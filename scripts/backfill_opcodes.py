#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
为已拉取成功的交易补齐 opcode 目录（debug_traceTransaction）。

策略：
- 从 ctf 读取交易列表（含链信息）
- 仅处理满足以下条件的 tx：
  - transactions/<tx>/README.md 存在（表示该笔交易已成功拉取过）
  - transactions/<tx>/opcode/ 不存在或不包含 tx_assembly_*.json/.asm.txt
  - log/<tx>/ 下存在 tx_trace_*.json（用于 --reuse-log 复用）
- 对每笔调用：
  python scripts/pull_artifacts.py --network <mapped> --tx <tx> --reuse-log --timeout <N>

用法（从仓库根目录）：
  source venv/bin/activate
  python scripts/backfill_opcodes.py
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Set, Tuple


CHAIN_TO_NETWORK: Dict[str, str] = {
    "Polygon_Amoy": "polygon_amoy",
    "Ethereum_Sepolia": "sepolia",
    "Ethereum_Mainnet": "eth",
    "Polygon Amoy": "polygon_amoy",
    "Ethereum Sepolia": "sepolia",
    "Ethereum Mainnet": "eth",
}


def _load_ctf_entries(ctf_path: Path) -> List[dict]:
    raw = ctf_path.read_text(encoding="utf-8").strip()
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as e:
        raise RuntimeError(f"ctf 文件不是有效 JSON：{ctf_path} ({e})") from e
    if not isinstance(data, list):
        raise RuntimeError(f"ctf 内容必须是 JSON list：{ctf_path}")
    return [x for x in data if isinstance(x, dict)]


def _iter_txs(entries: List[dict]) -> Iterable[Tuple[str, str]]:
    for e in entries:
        chain = str(e.get("chain") or "").strip()
        if not chain:
            continue
        network = CHAIN_TO_NETWORK.get(chain)
        if not network:
            raise RuntimeError(f"未知 chain={chain}（请在 CHAIN_TO_NETWORK 里补映射）")

        if isinstance(e.get("tx_hash"), str) and e["tx_hash"].startswith("0x"):
            yield network, e["tx_hash"]
        elif isinstance(e.get("tx_hashes"), list):
            for tx in e["tx_hashes"]:
                if isinstance(tx, str) and tx.startswith("0x"):
                    yield network, tx


def _has_opcode(tx_dir: Path) -> bool:
    op = tx_dir / "opcode"
    if not op.exists() or not op.is_dir():
        return False
    has_json = any(op.glob("tx_assembly_*.json"))
    has_txt = any(op.glob("tx_assembly_*.asm.txt"))
    return bool(has_json or has_txt)


def _log_has_trace(tx: str) -> bool:
    tx_short = tx[:10]
    tx_log_dir = Path("log") / tx
    if tx_log_dir.exists():
        if any(tx_log_dir.glob(f"tx_trace_{tx_short}_*.json")):
            return True
    if Path("log").exists() and any(Path("log").glob(f"tx_trace_{tx_short}_*.json")):
        return True
    return False


def main() -> int:
    p = argparse.ArgumentParser(description="Backfill opcode artifacts for existing tx dirs")
    p.add_argument("--ctf", default="ctf", help="ctf 文件路径（默认: ./ctf）")
    p.add_argument("--timeout", type=int, default=600, help="debug_traceTransaction timeout seconds")
    p.add_argument(
        "--all-existing",
        action="store_true",
        help="忽略 ctf，仅对 transactions/ 下所有已存在 tx 目录补 opcode（需要 tx_dir/README.md + log/<tx>/trace）",
    )
    args = p.parse_args()

    repo_root = Path.cwd()
    pull_script = (repo_root / "scripts" / "pull_artifacts.py").resolve()
    if not pull_script.exists():
        print(f"scripts/pull_artifacts.py 不存在：{pull_script}", file=sys.stderr)
        return 2

    targets: List[Tuple[str, str]] = []
    if args.all_existing:
        print("错误：--all-existing 需要链信息，当前实现不支持。请使用默认模式（从 ctf 读取）。", file=sys.stderr)
        return 2
    else:
        ctf_path = (repo_root / args.ctf).resolve()
        if not ctf_path.exists():
            print(f"ctf 文件不存在：{ctf_path}", file=sys.stderr)
            return 2
        entries = _load_ctf_entries(ctf_path)
        targets = list(_iter_txs(entries))

    seen: Set[Tuple[str, str]] = set()
    ordered: List[Tuple[str, str]] = []
    for network, tx in targets:
        key = (network, tx)
        if key in seen:
            continue
        seen.add(key)
        ordered.append(key)

    total = len(ordered)
    if total == 0:
        print("未找到任何目标 tx。")
        return 0

    to_run: List[Tuple[str, str, str]] = []
    skipped: List[Tuple[str, str, str]] = []

    for network, tx in ordered:
        tx_dir = Path("transactions") / tx
        if not (tx_dir / "README.md").exists():
            skipped.append((network, tx, "no_transactions_readme"))
            continue
        if _has_opcode(tx_dir):
            skipped.append((network, tx, "already_has_opcode"))
            continue
        if not _log_has_trace(tx):
            skipped.append((network, tx, "no_log_trace_for_reuse"))
            continue
        to_run.append((network, tx, "missing_opcode"))

    print(f"总计(来自ctf)：{total} 笔")
    print(f"需要补opcode：{len(to_run)} 笔")
    if skipped:
        print(f"跳过：{len(skipped)} 笔（已存在opcode/未成功拉取/缺log）")

    failures: List[Tuple[str, str, int]] = []

    for i, (network, tx, _) in enumerate(to_run, start=1):
        cmd = [
            sys.executable,
            str(pull_script),
            "--network",
            network,
            "--tx",
            tx,
            "--reuse-log",
            "--timeout",
            str(args.timeout),
        ]
        print(f"[{i}/{len(to_run)}] 补opcode：{tx} ({network})")
        r = subprocess.run(cmd, cwd=str(repo_root), check=False)
        if r.returncode != 0:
            failures.append((network, tx, r.returncode))
            print(f"  -> 失败：exit={r.returncode}")

    if failures:
        print("\n以下交易补 opcode 失败：")
        for network, tx, code in failures:
            print(f"- {tx} ({network}) exit={code}")
        return 1

    print("\n补 opcode 完成。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
