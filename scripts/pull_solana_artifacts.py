#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Pull detailed Solana transaction artifacts into transactions/<signature>/.

Unlike EVM RPCs, standard Solana RPC does not expose opcode-level execution traces
or verified program source code. This script persists the most detailed data that
standard RPC can provide:

1) trace/
   - raw getTransaction outputs (`json`, `jsonParsed`, `base64`)
   - signature status / block / logs / rewards / balance diffs
   - per-instruction files for outer + inner instructions
2) accounts/
   - per-account snapshots for every touched account (`base64` + `jsonParsed`)
3) contracts/
   - one summary json per invoked program/program account
4) contract_sources/
   - per-program low-level artifacts (program account / ProgramData / raw bytes)
5) opcode/
   - capability note explaining why opcode traces are unavailable via standard RPC

Usage (from repo root):
  source venv/bin/activate
  python scripts/pull_solana_artifacts.py --tx <SOLANA_SIGNATURE>
"""

from __future__ import annotations

import argparse
import base64
import json
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Sequence

import requests


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CONFIG = ROOT / "config.json"
BPF_LOADER = "BPFLoader1111111111111111111111111111111111"
BPF_LOADER_DEPRECATED = "BPFLoader2111111111111111111111111111111111"
BPF_LOADER_UPGRADEABLE = "BPFLoaderUpgradeab1e11111111111111111111111"


def _load_config(config_path: Path) -> Dict[str, Any]:
    with config_path.open("r", encoding="utf-8") as f:
        return json.load(f)


def _write_json(path: Path, obj: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, indent=2, ensure_ascii=False), encoding="utf-8")


def _write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def _write_bytes(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)


def _chunked(values: Sequence[str], size: int) -> Iterable[List[str]]:
    for i in range(0, len(values), size):
        yield list(values[i : i + size])


def _safe_name(value: str) -> str:
    return "".join(ch if ch.isalnum() or ch in ("-", "_", ".") else "_" for ch in value)


def _b64decode_field(data_field: Any) -> bytes:
    if isinstance(data_field, list) and len(data_field) >= 1 and isinstance(data_field[0], str):
        return base64.b64decode(data_field[0])
    if isinstance(data_field, str):
        return base64.b64decode(data_field)
    return b""


def _parse_u32_le(data: bytes, offset: int) -> Optional[int]:
    if len(data) < offset + 4:
        return None
    return int.from_bytes(data[offset : offset + 4], "little")


def _parse_u64_le(data: bytes, offset: int) -> Optional[int]:
    if len(data) < offset + 8:
        return None
    return int.from_bytes(data[offset : offset + 8], "little")


def _extract_programdata_address(program_account_raw: bytes) -> Optional[str]:
    state = _parse_u32_le(program_account_raw, 0)
    if state != 2 or len(program_account_raw) < 36:
        return None
    programdata_bytes = program_account_raw[4:36]
    return _encode_base58(programdata_bytes)


def _parse_programdata_state(programdata_raw: bytes) -> Dict[str, Any]:
    state = _parse_u32_le(programdata_raw, 0)
    out: Dict[str, Any] = {
        "loader_state": state,
        "raw_len": len(programdata_raw),
    }
    if state != 3 or len(programdata_raw) < 13:
        return out

    slot = _parse_u64_le(programdata_raw, 4)
    authority_option = programdata_raw[12]
    authority: Optional[str] = None
    program_bytes_offset = 13
    if authority_option == 1 and len(programdata_raw) >= 45:
        authority = _encode_base58(programdata_raw[13:45])
        program_bytes_offset = 45

    out.update(
        {
            "slot": slot,
            "upgrade_authority_option": authority_option,
            "upgrade_authority_address": authority,
            "program_bytes_offset": program_bytes_offset,
            "program_bytes_len": max(0, len(programdata_raw) - program_bytes_offset),
        }
    )
    return out


_BASE58_ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"


def _encode_base58(data: bytes) -> str:
    if not data:
        return ""
    n = int.from_bytes(data, "big")
    encoded = ""
    while n > 0:
        n, rem = divmod(n, 58)
        encoded = _BASE58_ALPHABET[rem] + encoded

    leading_zeros = 0
    for b in data:
        if b == 0:
            leading_zeros += 1
        else:
            break
    return ("1" * leading_zeros) + (encoded or "1")


@dataclass
class SolanaRpcClient:
    rpc_url: str
    timeout: int

    def call(self, method: str, params: Sequence[Any]) -> Dict[str, Any]:
        payload = {"jsonrpc": "2.0", "id": 1, "method": method, "params": list(params)}
        response = requests.post(self.rpc_url, json=payload, timeout=self.timeout)
        response.raise_for_status()
        body = response.json()
        if isinstance(body, dict) and body.get("error"):
            raise RuntimeError(f"{method} failed: {body['error']}")
        return body


def _get_result(resp: Dict[str, Any]) -> Any:
    return resp.get("result") if isinstance(resp, dict) else None


def _normalize_account_keys(parsed_tx: Optional[Dict[str, Any]], raw_tx: Optional[Dict[str, Any]]) -> List[Dict[str, Any]]:
    tx = parsed_tx or raw_tx or {}
    message = ((tx.get("transaction") or {}).get("message") or {})
    account_keys = message.get("accountKeys") or []
    out: List[Dict[str, Any]] = []
    for idx, entry in enumerate(account_keys):
        if isinstance(entry, str):
            out.append({"index": idx, "pubkey": entry})
        elif isinstance(entry, dict):
            normalized = {"index": idx, **entry}
            if "pubkey" not in normalized and "address" in normalized:
                normalized["pubkey"] = normalized["address"]
            out.append(normalized)
    return out


def _pubkeys_from_account_keys(account_keys: Sequence[Dict[str, Any]]) -> List[str]:
    out: List[str] = []
    for entry in account_keys:
        pubkey = entry.get("pubkey")
        if isinstance(pubkey, str):
            out.append(pubkey)
    return out


def _get_loaded_addresses(parsed_tx: Optional[Dict[str, Any]], raw_tx: Optional[Dict[str, Any]]) -> Dict[str, List[str]]:
    for tx in (parsed_tx, raw_tx):
        meta = (tx or {}).get("meta") or {}
        loaded = meta.get("loadedAddresses")
        if isinstance(loaded, dict):
            return {
                "writable": [x for x in loaded.get("writable", []) if isinstance(x, str)],
                "readonly": [x for x in loaded.get("readonly", []) if isinstance(x, str)],
            }
    return {"writable": [], "readonly": []}


def _get_program_id(inst: Dict[str, Any]) -> Optional[str]:
    for key in ("programId", "program_id"):
        value = inst.get(key)
        if isinstance(value, str):
            return value
    program_id_index = inst.get("programIdIndex")
    if program_id_index is not None:
        return str(program_id_index)
    return None


def _collect_instruction_records(parsed_tx: Optional[Dict[str, Any]]) -> List[Dict[str, Any]]:
    if not parsed_tx:
        return []

    tx = parsed_tx.get("transaction") or {}
    message = tx.get("message") or {}
    meta = parsed_tx.get("meta") or {}
    outer_instructions = message.get("instructions") or []
    inner_groups = meta.get("innerInstructions") or []

    records: List[Dict[str, Any]] = []
    for outer_idx, inst in enumerate(outer_instructions):
        if not isinstance(inst, dict):
            continue
        records.append(
            {
                "kind": "outer",
                "outer_index": outer_idx,
                "inner_index": None,
                "program_id": _get_program_id(inst),
                "program": inst.get("program"),
                "stack_height": inst.get("stackHeight"),
                "accounts": inst.get("accounts"),
                "data": inst.get("data"),
                "parsed": inst.get("parsed"),
                "raw": inst,
            }
        )

    for group in inner_groups:
        if not isinstance(group, dict):
            continue
        outer_idx = group.get("index")
        instructions = group.get("instructions") or []
        for inner_idx, inst in enumerate(instructions):
            if not isinstance(inst, dict):
                continue
            records.append(
                {
                    "kind": "inner",
                    "outer_index": outer_idx,
                    "inner_index": inner_idx,
                    "program_id": _get_program_id(inst),
                    "program": inst.get("program"),
                    "stack_height": inst.get("stackHeight"),
                    "accounts": inst.get("accounts"),
                    "data": inst.get("data"),
                    "parsed": inst.get("parsed"),
                    "raw": inst,
                }
            )
    return records


def _collect_touched_pubkeys(
    account_keys: Sequence[Dict[str, Any]],
    loaded_addresses: Dict[str, List[str]],
    instruction_records: Sequence[Dict[str, Any]],
) -> List[str]:
    ordered: List[str] = []
    seen = set()

    def add(value: Optional[str]) -> None:
        if value and value not in seen:
            ordered.append(value)
            seen.add(value)

    for pubkey in _pubkeys_from_account_keys(account_keys):
        add(pubkey)
    for pubkey in loaded_addresses.get("writable", []):
        add(pubkey)
    for pubkey in loaded_addresses.get("readonly", []):
        add(pubkey)
    for inst in instruction_records:
        add(inst.get("program_id"))
        accounts = inst.get("accounts")
        if isinstance(accounts, list):
            for account in accounts:
                if isinstance(account, str):
                    add(account)
    return ordered


def _build_lamport_diffs(
    account_keys: Sequence[Dict[str, Any]],
    parsed_tx: Optional[Dict[str, Any]],
) -> List[Dict[str, Any]]:
    if not parsed_tx:
        return []
    meta = parsed_tx.get("meta") or {}
    pre = meta.get("preBalances") or []
    post = meta.get("postBalances") or []
    out: List[Dict[str, Any]] = []
    for idx, account in enumerate(account_keys):
        if idx >= len(pre) or idx >= len(post):
            continue
        pubkey = account.get("pubkey")
        if not isinstance(pubkey, str):
            continue
        diff = int(post[idx]) - int(pre[idx])
        out.append(
            {
                "index": idx,
                "pubkey": pubkey,
                "pre_lamports": pre[idx],
                "post_lamports": post[idx],
                "delta_lamports": diff,
                "delta_sol": diff / 1_000_000_000,
                "signer": account.get("signer"),
                "writable": account.get("writable"),
                "source": account.get("source"),
            }
        )
    return out


def _ui_amount_entry(entry: Dict[str, Any]) -> Dict[str, Any]:
    ui = entry.get("uiTokenAmount") or {}
    return {
        "mint": entry.get("mint"),
        "owner": entry.get("owner"),
        "programId": entry.get("programId"),
        "uiTokenAmount": ui,
    }


def _build_token_balance_diffs(parsed_tx: Optional[Dict[str, Any]]) -> List[Dict[str, Any]]:
    if not parsed_tx:
        return []
    meta = parsed_tx.get("meta") or {}
    pre_balances = meta.get("preTokenBalances") or []
    post_balances = meta.get("postTokenBalances") or []
    pre_indexed = {(entry.get("accountIndex"), entry.get("mint")): entry for entry in pre_balances if isinstance(entry, dict)}
    post_indexed = {(entry.get("accountIndex"), entry.get("mint")): entry for entry in post_balances if isinstance(entry, dict)}
    keys = sorted(set(pre_indexed) | set(post_indexed), key=lambda item: (item[0], item[1] or ""))

    out: List[Dict[str, Any]] = []
    for key in keys:
        pre = pre_indexed.get(key)
        post = post_indexed.get(key)
        out.append(
            {
                "accountIndex": key[0],
                "mint": key[1],
                "pre": _ui_amount_entry(pre) if pre else None,
                "post": _ui_amount_entry(post) if post else None,
            }
        )
    return out


def _program_invocation_summary(instruction_records: Sequence[Dict[str, Any]]) -> Dict[str, Dict[str, Any]]:
    out: Dict[str, Dict[str, Any]] = {}
    for inst in instruction_records:
        program_id = inst.get("program_id")
        if not isinstance(program_id, str):
            continue
        item = out.setdefault(program_id, {"outer_calls": 0, "inner_calls": 0, "occurrences": []})
        if inst.get("kind") == "outer":
            item["outer_calls"] += 1
        else:
            item["inner_calls"] += 1
        item["occurrences"].append(
            {
                "kind": inst.get("kind"),
                "outer_index": inst.get("outer_index"),
                "inner_index": inst.get("inner_index"),
                "program": inst.get("program"),
                "stack_height": inst.get("stack_height"),
            }
        )
    return out


def _summary(parsed_tx: Optional[Dict[str, Any]], status: Optional[Dict[str, Any]], invocation_summary: Dict[str, Dict[str, Any]]) -> Dict[str, Any]:
    if not parsed_tx:
        return {}
    tx = parsed_tx.get("transaction") or {}
    meta = parsed_tx.get("meta") or {}
    message = tx.get("message") or {}
    account_keys = _normalize_account_keys(parsed_tx, None)
    signers = [item.get("pubkey") for item in account_keys if item.get("signer")]
    return {
        "signature": ((tx.get("signatures") or [None])[0]),
        "slot": parsed_tx.get("slot"),
        "blockTime": parsed_tx.get("blockTime"),
        "blockTime_iso": datetime.fromtimestamp(parsed_tx["blockTime"], tz=timezone.utc).isoformat() if parsed_tx.get("blockTime") else None,
        "version": parsed_tx.get("version"),
        "recentBlockhash": message.get("recentBlockhash"),
        "fee_lamports": meta.get("fee"),
        "fee_sol": (meta.get("fee") or 0) / 1_000_000_000,
        "success": meta.get("err") is None,
        "err": meta.get("err"),
        "confirmationStatus": (status or {}).get("confirmationStatus"),
        "confirmations": (status or {}).get("confirmations"),
        "computeUnitsConsumed": meta.get("computeUnitsConsumed"),
        "costUnits": meta.get("costUnits"),
        "loadedAccountsDataSize": meta.get("loadedAccountsDataSize"),
        "numRequiredSignatures": (message.get("header") or {}).get("numRequiredSignatures"),
        "numReadonlySignedAccounts": (message.get("header") or {}).get("numReadonlySignedAccounts"),
        "numReadonlyUnsignedAccounts": (message.get("header") or {}).get("numReadonlyUnsignedAccounts"),
        "signers": signers,
        "invoked_programs": sorted(invocation_summary.keys()),
        "outer_instruction_count": len(message.get("instructions") or []),
        "inner_instruction_group_count": len((meta.get("innerInstructions") or [])),
        "log_count": len(meta.get("logMessages") or []),
    }


def _fetch_multiple_accounts(
    client: SolanaRpcClient,
    pubkeys: Sequence[str],
    *,
    encoding: str,
) -> Dict[str, Any]:
    results: Dict[str, Any] = {}
    for chunk in _chunked(list(pubkeys), 100):
        resp = client.call("getMultipleAccounts", [chunk, {"encoding": encoding, "commitment": "finalized"}])
        values = (_get_result(resp) or {}).get("value") or []
        for pubkey, value in zip(chunk, values):
            results[pubkey] = value
    return results


def _build_account_summary(pubkey: str, raw_account: Any, parsed_account: Any) -> Dict[str, Any]:
    def pick(field: str) -> Any:
        if isinstance(parsed_account, dict) and field in parsed_account:
            return parsed_account.get(field)
        if isinstance(raw_account, dict) and field in raw_account:
            return raw_account.get(field)
        return None

    data_len = None
    if isinstance(raw_account, dict):
        data = raw_account.get("data")
        raw_bytes = _b64decode_field(data)
        if raw_bytes:
            data_len = len(raw_bytes)

    return {
        "pubkey": pubkey,
        "exists": raw_account is not None or parsed_account is not None,
        "lamports": pick("lamports"),
        "owner": pick("owner"),
        "executable": pick("executable"),
        "rentEpoch": pick("rentEpoch"),
        "space": pick("space"),
        "data_len": data_len,
    }


def _write_instruction_files(trace_dir: Path, instruction_records: Sequence[Dict[str, Any]]) -> None:
    instructions_dir = trace_dir / "instructions"
    instructions_dir.mkdir(parents=True, exist_ok=True)

    index: List[Dict[str, Any]] = []
    for record in instruction_records:
        outer_idx = record.get("outer_index")
        inner_idx = record.get("inner_index")
        if record.get("kind") == "outer":
            filename = f"{int(outer_idx):03d}_outer.json"
        else:
            filename = f"{int(outer_idx):03d}_inner_{int(inner_idx):02d}.json"
        _write_json(instructions_dir / filename, record)
        index.append(
            {
                "file": filename,
                "kind": record.get("kind"),
                "outer_index": outer_idx,
                "inner_index": inner_idx,
                "program_id": record.get("program_id"),
                "program": record.get("program"),
            }
        )

    _write_json(instructions_dir / "__index__.json", index)


def _write_account_files(tx_dir: Path, raw_accounts: Dict[str, Any], parsed_accounts: Dict[str, Any]) -> Dict[str, Dict[str, Any]]:
    accounts_dir = tx_dir / "accounts"
    summaries: Dict[str, Dict[str, Any]] = {}
    for pubkey in sorted(set(raw_accounts) | set(parsed_accounts)):
        safe_pubkey = _safe_name(pubkey)
        account_dir = accounts_dir / safe_pubkey
        raw_account = raw_accounts.get(pubkey)
        parsed_account = parsed_accounts.get(pubkey)
        _write_json(account_dir / "account_info_base64.json", raw_account)
        _write_json(account_dir / "account_info_jsonParsed.json", parsed_account)
        summary = _build_account_summary(pubkey, raw_account, parsed_account)
        _write_json(account_dir / "summary.json", summary)
        summaries[pubkey] = summary
    _write_json(accounts_dir / "__index__.json", list(summaries.values()))
    return summaries


def _write_program_files(
    tx_dir: Path,
    invocation_summary: Dict[str, Dict[str, Any]],
    raw_accounts: Dict[str, Any],
    parsed_accounts: Dict[str, Any],
) -> None:
    contracts_dir = tx_dir / "contracts"
    sources_dir = tx_dir / "contract_sources"
    opcode_dir = tx_dir / "opcode"
    opcode_dir.mkdir(parents=True, exist_ok=True)

    capabilities = {
        "opcode_trace_available": False,
        "why": "Standard Solana RPC does not expose VM opcode-level traces like EVM debug_traceTransaction.",
        "low_level_artifacts_written": [
            "contracts/<program>.json",
            "contract_sources/<program>/program_account*.json",
            "contract_sources/<program>/programdata_account*.json",
            "contract_sources/<program>/program_binary.*",
        ],
    }
    _write_json(opcode_dir / "capabilities.json", capabilities)
    _write_text(
        opcode_dir / "README.md",
        "Solana standard RPC does not provide opcode-level execution traces.\n"
        "This directory therefore contains only capability notes; low-level executable bytes are stored under contract_sources/.\n",
    )

    loader_ids = {BPF_LOADER, BPF_LOADER_DEPRECATED, BPF_LOADER_UPGRADEABLE}
    program_index: List[Dict[str, Any]] = []

    for program_id, invocations in sorted(invocation_summary.items()):
        raw_account = raw_accounts.get(program_id)
        parsed_account = parsed_accounts.get(program_id)
        contract_summary = _build_account_summary(program_id, raw_account, parsed_account)
        contract_summary.update(
            {
                "program_id": program_id,
                "invocations": invocations,
                "loader_type": "unknown",
                "programdata_address": None,
                "program_binary_len": None,
                "upgrade_authority_address": None,
            }
        )

        source_program_dir = sources_dir / _safe_name(program_id)
        _write_json(source_program_dir / "program_account_base64.json", raw_account)
        _write_json(source_program_dir / "program_account_jsonParsed.json", parsed_account)

        owner = contract_summary.get("owner")
        raw_bytes = b""
        if isinstance(raw_account, dict):
            raw_bytes = _b64decode_field(raw_account.get("data"))

        if owner in loader_ids:
            contract_summary["loader_type"] = owner
            if owner == BPF_LOADER_UPGRADEABLE:
                programdata_address = _extract_programdata_address(raw_bytes)
                contract_summary["programdata_address"] = programdata_address
                if programdata_address:
                    programdata_raw = raw_accounts.get(programdata_address)
                    programdata_parsed = parsed_accounts.get(programdata_address)
                    _write_json(source_program_dir / "programdata_account_base64.json", programdata_raw)
                    _write_json(source_program_dir / "programdata_account_jsonParsed.json", programdata_parsed)

                    programdata_bytes = b""
                    if isinstance(programdata_raw, dict):
                        programdata_bytes = _b64decode_field(programdata_raw.get("data"))
                    programdata_state = _parse_programdata_state(programdata_bytes)
                    contract_summary["programdata_state"] = programdata_state
                    contract_summary["upgrade_authority_address"] = programdata_state.get("upgrade_authority_address")

                    program_offset = programdata_state.get("program_bytes_offset")
                    if isinstance(program_offset, int) and program_offset <= len(programdata_bytes):
                        program_bytes = programdata_bytes[program_offset:]
                        contract_summary["program_binary_len"] = len(program_bytes)
                        _write_bytes(source_program_dir / "program_binary.so", program_bytes)
                        _write_text(
                            source_program_dir / "program_binary.base64.txt",
                            base64.b64encode(program_bytes).decode("ascii"),
                        )
            else:
                if raw_bytes:
                    contract_summary["program_binary_len"] = len(raw_bytes)
                    _write_bytes(source_program_dir / "program_binary.so", raw_bytes)
                    _write_text(
                        source_program_dir / "program_binary.base64.txt",
                        base64.b64encode(raw_bytes).decode("ascii"),
                    )
        else:
            contract_summary["loader_type"] = owner

        contract_summary["rpc_source_code_available"] = False
        contract_summary["source_note"] = "Solana RPC cannot return verified source code; only account metadata and executable bytes are available."

        _write_json(contracts_dir / f"{_safe_name(program_id)}.json", contract_summary)
        _write_json(source_program_dir / "summary.json", contract_summary)
        program_index.append(contract_summary)

    _write_json(contracts_dir / "__index__.json", program_index)
    _write_json(sources_dir / "__index__.json", program_index)


def pull_solana_artifacts(
    tx_sig: str,
    *,
    network: str = "solana",
    config_path: Path = DEFAULT_CONFIG,
    timeout: int = 45,
    max_supported_transaction_version: int = 0,
) -> Path:
    config = _load_config(Path(config_path))
    networks = config.get("networks") or {}
    network_cfg = networks.get(network)
    if not isinstance(network_cfg, dict):
        raise ValueError(f"Unsupported network: {network}. Supported networks: {list(networks.keys())}")
    rpc_url = network_cfg.get("rpc_url")
    if not isinstance(rpc_url, str) or not rpc_url:
        raise ValueError(f"Network {network} is missing rpc_url in {config_path}")

    client = SolanaRpcClient(rpc_url=rpc_url, timeout=timeout)
    tx_dir = ROOT / "transactions" / tx_sig
    trace_dir = tx_dir / "trace"
    trace_dir.mkdir(parents=True, exist_ok=True)

    tx_json = _get_result(
        client.call(
            "getTransaction",
            [tx_sig, {"encoding": "json", "commitment": "finalized", "maxSupportedTransactionVersion": max_supported_transaction_version}],
        )
    )
    tx_json_parsed = _get_result(
        client.call(
            "getTransaction",
            [tx_sig, {"encoding": "jsonParsed", "commitment": "finalized", "maxSupportedTransactionVersion": max_supported_transaction_version}],
        )
    )
    tx_base64 = _get_result(
        client.call(
            "getTransaction",
            [tx_sig, {"encoding": "base64", "commitment": "finalized", "maxSupportedTransactionVersion": max_supported_transaction_version}],
        )
    )
    if tx_json is None or tx_json_parsed is None or tx_base64 is None:
        raise RuntimeError(f"Transaction not found or unavailable via RPC: {tx_sig}")

    status_resp = client.call("getSignatureStatuses", [[tx_sig], {"searchTransactionHistory": True}])
    status = ((_get_result(status_resp) or {}).get("value") or [None])[0]
    slot = tx_json_parsed.get("slot")
    block_resp = client.call(
        "getBlock",
        [slot, {"encoding": "json", "transactionDetails": "full", "rewards": True, "maxSupportedTransactionVersion": max_supported_transaction_version}],
    )
    block = _get_result(block_resp)
    version_resp = client.call("getVersion", [])
    rpc_version = _get_result(version_resp)

    account_keys = _normalize_account_keys(tx_json_parsed, tx_json)
    loaded_addresses = _get_loaded_addresses(tx_json_parsed, tx_json)
    instruction_records = _collect_instruction_records(tx_json_parsed)
    touched_pubkeys = _collect_touched_pubkeys(account_keys, loaded_addresses, instruction_records)
    invocation_summary = _program_invocation_summary(instruction_records)

    raw_accounts = _fetch_multiple_accounts(client, touched_pubkeys, encoding="base64")

    # Some upgradeable program binaries live in separate ProgramData accounts; fetch them as well.
    extra_programdata_pubkeys: List[str] = []
    for program_id in invocation_summary:
        raw_account = raw_accounts.get(program_id)
        if not isinstance(raw_account, dict):
            continue
        if raw_account.get("owner") != BPF_LOADER_UPGRADEABLE:
            continue
        programdata_address = _extract_programdata_address(_b64decode_field(raw_account.get("data")))
        if programdata_address and programdata_address not in raw_accounts and programdata_address not in extra_programdata_pubkeys:
            extra_programdata_pubkeys.append(programdata_address)

    if extra_programdata_pubkeys:
        raw_accounts.update(_fetch_multiple_accounts(client, extra_programdata_pubkeys, encoding="base64"))
        touched_pubkeys.extend([p for p in extra_programdata_pubkeys if p not in touched_pubkeys])

    parsed_accounts = _fetch_multiple_accounts(client, touched_pubkeys, encoding="jsonParsed")

    lamport_diffs = _build_lamport_diffs(account_keys, tx_json_parsed)
    token_balance_diffs = _build_token_balance_diffs(tx_json_parsed)

    _write_json(trace_dir / "transaction_json.json", tx_json)
    _write_json(trace_dir / "transaction_jsonParsed.json", tx_json_parsed)
    _write_json(trace_dir / "transaction_base64.json", tx_base64)
    _write_json(trace_dir / "signature_status.json", status)
    _write_json(trace_dir / "slot_block.json", block)
    _write_json(trace_dir / "rpc_version.json", rpc_version)
    _write_json(trace_dir / "accounts_touched.json", touched_pubkeys)
    _write_json(trace_dir / "account_keys.json", account_keys)
    _write_json(trace_dir / "loaded_addresses.json", loaded_addresses)
    _write_json(trace_dir / "program_invocations.json", invocation_summary)
    _write_json(trace_dir / "lamport_diffs.json", lamport_diffs)
    _write_json(trace_dir / "token_balance_diffs.json", token_balance_diffs)
    _write_json(trace_dir / "log_messages.json", (tx_json_parsed.get("meta") or {}).get("logMessages") or [])
    _write_json(trace_dir / "rewards.json", (tx_json_parsed.get("meta") or {}).get("rewards"))
    _write_json(trace_dir / "return_data.json", (tx_json_parsed.get("meta") or {}).get("returnData"))
    _write_json(trace_dir / "summary.json", _summary(tx_json_parsed, status, invocation_summary))
    _write_instruction_files(trace_dir, instruction_records)

    account_summaries = _write_account_files(tx_dir, raw_accounts, parsed_accounts)
    _write_program_files(tx_dir, invocation_summary, raw_accounts, parsed_accounts)

    generated_at = datetime.now(tz=timezone.utc).isoformat()
    readme = f"""## Solana Transaction Artifacts

- `network`: `{network}`
- `signature`: `{tx_sig}`
- `generated_at`: `{generated_at}`

### Directory Structure

- `trace/`
  - `transaction_json.json`: `getTransaction(..., encoding="json")`
  - `transaction_jsonParsed.json`: `getTransaction(..., encoding="jsonParsed")`
  - `transaction_base64.json`: raw wire transaction bytes from RPC
  - `instructions/`: one file per outer / inner instruction
  - `log_messages.json`, `lamport_diffs.json`, `token_balance_diffs.json`, `slot_block.json`
- `accounts/`
  - `<pubkey>/account_info_base64.json`
  - `<pubkey>/account_info_jsonParsed.json`
  - `<pubkey>/summary.json`
- `contracts/`
  - `<program_id>.json`: invoked program summaries
- `contract_sources/`
  - `<program_id>/program_account*.json`
  - `<program_id>/programdata_account*.json` (upgradeable programs when available)
  - `<program_id>/program_binary.so` / `program_binary.base64.txt`
- `opcode/`
  - Solana standard RPC cannot provide opcode-level traces; see `capabilities.json`

### RPC Limits vs EVM

- No Solana standard RPC equivalent to EVM `debug_traceTransaction`
- No verified on-chain source retrieval via standard RPC
- Best-effort low-level executable bytes are stored for invoked executable programs

### Regenerate

```bash
source venv/bin/activate
python scripts/pull_artifacts.py --network {network} --tx {tx_sig}
```
"""
    _write_text(tx_dir / "README.md", readme)
    _write_json(
        tx_dir / "manifest.json",
        {
            "network": network,
            "signature": tx_sig,
            "generated_at": generated_at,
            "rpc_url": rpc_url,
            "files_written": {
                "accounts": len(account_summaries),
                "invoked_programs": len(invocation_summary),
                "instruction_records": len(instruction_records),
            },
        },
    )

    print(f"Done. Solana transaction directory: {tx_dir}")
    return tx_dir


def main() -> int:
    parser = argparse.ArgumentParser(description="Pull detailed Solana transaction artifacts into transactions/<signature>/")
    parser.add_argument("--tx", required=True, help="Solana transaction signature")
    parser.add_argument("--network", default="solana", help="Network key in config.json (default: solana)")
    parser.add_argument("--config", default=str(DEFAULT_CONFIG), help="Path to config.json")
    parser.add_argument("--timeout", type=int, default=45, help="RPC timeout seconds")
    parser.add_argument("--max-supported-transaction-version", type=int, default=0, help="maxSupportedTransactionVersion for getTransaction/getBlock")
    args = parser.parse_args()

    pull_solana_artifacts(
        args.tx,
        network=args.network,
        config_path=Path(args.config),
        timeout=args.timeout,
        max_supported_transaction_version=args.max_supported_transaction_version,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
