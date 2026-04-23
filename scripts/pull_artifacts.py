#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Pull transaction artifacts and persist them to transactions/<tx>/.

For EVM networks, this fetches trace splitting + opcode/structLogs + contract
source/decompilation + selector mapping.
For Solana, this fetches the most detailed standard-RPC artifacts available:
transaction/meta payloads, outer/inner instructions, logs, balance diffs,
account snapshots, and invoked program binaries/metadata.

Output structure:
1) trace: split into transactions/<tx>/trace/ (by trace_index and trace_address, reflecting order + depth)
2) opcode: exported to transactions/<tx>/opcode/ (json + human-readable txt)
3) contracts: transactions/<tx>/contracts/ (one json per address)
   - verified: transactions/<tx>/contract_sources/<addr>/... (multi-file project + ABI)
   - unverified: transactions/<tx>/contract_sources/<addr>/decompiled/{raw.sol,optimized.sol,abi.json}
   - selector mapping: transactions/<tx>/contract_sources/<addr>/selectors_from_trace.json
4) readme: transactions/<tx>/README.md

Usage (from repo root):
  source venv/bin/activate
  python scripts/pull_artifacts.py --network bsc --tx 0x...
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import argparse
import json
from datetime import datetime
from typing import Any, Dict, List, Optional, Set

from pull_solana_artifacts import pull_solana_artifacts
from txanalyzer import TransactionTraceAnalyzer
from txanalyzer import TransactionProcessor


def _lower_addr(a: str) -> str:
    return (a or "").lower()


def _extract_selectors_by_to(trace_result: List[Dict[str, Any]]) -> Dict[str, Set[str]]:
    """
    Extract selector (method_id) sets from the raw trace_transaction result.

    Returns: to_address(lowercase) -> set(["0x12345678", ...])
    """
    out: Dict[str, Set[str]] = {}
    for t in trace_result:
        action = t.get("action") or {}
        to_addr = _lower_addr(action.get("to") or "")
        if not to_addr:
            continue
        inp = action.get("input") or ""
        if isinstance(inp, str) and inp.startswith("0x") and len(inp) >= 10:
            sel = inp[:10]
            out.setdefault(to_addr, set()).add(sel)
    return out


def _write_json(path: Path, obj: Any):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, indent=2, ensure_ascii=False), encoding="utf-8")

def _pick_latest(paths: List[Path]) -> Optional[Path]:
    if not paths:
        return None
    return max(paths, key=lambda p: p.stat().st_mtime)


def main() -> int:
    p = argparse.ArgumentParser(description="Pull tx artifacts into transactions/<tx>/")
    p.add_argument("--network", default="bsc")
    p.add_argument("--tx", required=True)
    p.add_argument("--timeout", type=int, default=120, help="RPC timeout seconds (trace/debug).")
    p.add_argument(
        "--reuse-log",
        action="store_true",
        help="Reuse existing log/tx_* files for this tx (avoid re-fetch/decompile).",
    )
    p.add_argument(
        "--skip-opcode",
        action="store_true",
        help="Skip debug_traceTransaction opcode export (useful when RPC times out).",
    )
    args = p.parse_args()

    tx = args.tx
    network = args.network

    if network == "solana":
        if args.reuse_log:
            print("Note: --reuse-log is only supported for EVM flows and will be ignored for Solana.")
        if args.skip_opcode:
            print("Note: Solana standard RPC has no opcode trace; opcode/ will contain capability notes only.")
        pull_solana_artifacts(tx, network=network, timeout=args.timeout)
        return 0

    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    tx_short = tx[:10]

    tx_log_dir = Path("log") / tx
    analyzer = TransactionTraceAnalyzer(network=network, log_dir=str(tx_log_dir), cache_dir="log")

    tx_dir = Path("transactions") / tx
    tx_dir.mkdir(parents=True, exist_ok=True)

    trace_json = ""
    calls_csv = ""
    contracts_json = ""
    report_path = ""

    if args.reuse_log:
        log_dir = tx_log_dir if tx_log_dir.exists() else Path("log")
        trace_file = _pick_latest(list(log_dir.glob(f"tx_trace_{tx_short}_*.json")))
        calls_file = _pick_latest(list(log_dir.glob(f"tx_calls_{tx_short}_*.csv")))
        contracts_file = _pick_latest(list(log_dir.glob(f"tx_contracts_{tx_short}_*.json")))
        report_file = _pick_latest(list(log_dir.glob(f"tx_report_{tx_short}_*.txt")))

        if not trace_file or not contracts_file or not report_file:
            raise RuntimeError(
                f"--reuse-log requires existing tx_trace/tx_contracts/tx_report files in log/ (tx_short={tx_short}), but none were found."
            )

        trace_json = str(trace_file)
        calls_csv = str(calls_file) if calls_file else ""
        contracts_json = str(contracts_file)
        report_path = str(report_file)

        processor = TransactionProcessor(log_dir=str(log_dir))
        processor.process_contracts(contracts_file, tx_dir)
        processor.process_trace(trace_file, tx_dir)
        processor.process_report(report_file, tx_dir)
    else:
        trace_resp = analyzer.get_transaction_trace(tx)
        parsed = analyzer.parse_trace_data(trace_resp)
        if "error" in parsed:
            raise RuntimeError(parsed["error"])

        trace_json = analyzer.save_to_json(parsed, filename=f"tx_trace_{tx_short}_{ts}.json")
        calls_csv = analyzer.save_to_csv(parsed, filename=f"tx_calls_{tx_short}_{ts}.csv")

        contract_addresses = parsed.get("contract_addresses", [])
        contract_info = analyzer.analyze_contracts(contract_addresses)
        contracts_json = analyzer.save_contract_info_to_json(contract_info, filename=f"tx_contracts_{tx_short}_{ts}.json")

        report = analyzer.generate_summary_report(parsed, contract_info)
        report_path = analyzer.save_report(report, filename=f"tx_report_{tx_short}_{ts}.txt")

        processor = TransactionProcessor(log_dir=str(tx_log_dir))
        processor.process_transaction(tx)

    # Export opcode (skip if already cached from a previous run)
    paths = {}
    opcode_error: str = ""
    if not args.skip_opcode:
        opcode_dir = tx_dir / "opcode"
        existing_opcodes = list(opcode_dir.glob("tx_assembly_*.json")) if opcode_dir.exists() else []
        if existing_opcodes:
            print(f"Opcode already cached ({len(existing_opcodes)} files), skipping debug_traceTransaction")
            paths = {"json": str(existing_opcodes[0])}
        else:
            try:
                paths = analyzer.export_transaction_assembly(
                    tx,
                    out_dir=str(opcode_dir),
                    timeout=args.timeout,
                    include_json=True,
                    include_text=True,
                    disable_storage=True,
                    disable_stack=True,
                    disable_memory=True,
                    enable_return_data=True,
                    text_max_lines=None,
                    text_max_stack_items=8,
                )
            except Exception as e:
                opcode_error = str(e)
                print(f"Warning: opcode export failed (continuing with remaining artifacts): {opcode_error}")

    # selector -> signature mapping
    trace_resp_for_selectors = analyzer.get_transaction_trace(tx)
    trace_result = trace_resp_for_selectors.get("result") if isinstance(trace_resp_for_selectors, dict) else None
    if not isinstance(trace_result, list):
        trace_result = []
    selectors_by_to = _extract_selectors_by_to(trace_result)

    for to_addr, selectors in selectors_by_to.items():
        clean = to_addr.replace("0x", "")
        out_path = tx_dir / "contract_sources" / clean / "selectors_from_trace.json"
        mapping = {sel: analyzer.get_function_signature_from_api(sel) for sel in sorted(selectors)}
        _write_json(out_path, {"address": to_addr, "selectors": mapping})

    # Generate transaction directory README
    readme = f"""## Transaction Artifacts Directory

- **network**: `{network}`
- **tx_hash**: `{tx}`
- **generated_at**: `{ts}`

### Directory Structure

- `trace/`
  - `transaction_info.json`: basic transaction info
  - `<trace_index>_<trace_address...>.json`: individual call record
    - **order**: `trace_index`
    - **depth**: length of `trace_address` array (longer = deeper)
- `contracts/`
  - `<address>.json`: contract info (verified status, ABI, decompilation status, etc.)
- `contract_sources/`
  - `<address>/`: source/decompiled/selector mapping for this address
    - `__index__.txt` (if verified source export succeeded)
    - `*.sol` / `*.abi.json` (if verified)
    - `decompiled/` (if unverified and decompilation succeeded)
      - `raw.sol`
      - `optimized.sol` (may equal raw if no AI env vars are set)
      - `abi.json`
    - `selectors_from_trace.json`: selector -> signature mapping from this tx trace (via openchain)
- `opcode/`
  - `tx_assembly_{{tx_short}}_*.json`: `debug_traceTransaction` structLogs (instruction-level)
  - `tx_assembly_{{tx_short}}_*.asm.txt`: human-readable opcode listing
  - Note: this directory may be missing if RPC does not support it or times out; use `--skip-opcode` to skip, or increase `--timeout` to retry.

### Source Files (raw files in log/)

- `{trace_json}`
- `{calls_csv}`
- `{contracts_json}`
- `{report_path}`

### Regenerate

```bash
source venv/bin/activate
python scripts/pull_artifacts.py --network {network} --tx {tx}
```
"""
    (tx_dir / "README.md").write_text(readme, encoding="utf-8")

    analyzer._save_function_signature_cache()

    print("Done. Transaction directory:", tx_dir)
    if paths:
        print("opcode output:", paths)
    if opcode_error:
        print("opcode export error:", opcode_error)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
