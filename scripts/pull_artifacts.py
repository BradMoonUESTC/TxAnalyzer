#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
一键拉取交易产物（trace拆分 + opcode(structLogs) + 合约源码/反编译 + selector映射），并落盘到 transactions/<tx>/。

满足输出要求：
1) trace：拆分到 transactions/<tx>/trace/（按 trace_index 与 trace_address，体现顺序+深度）
2) opcode：导出到 transactions/<tx>/opcode/（json + 人类可读txt）
3) 合约：transactions/<tx>/contracts/（每地址一个json）
   - 有源码：transactions/<tx>/contract_sources/<addr>/...（多文件工程 + ABI）
   - 无源码：transactions/<tx>/contract_sources/<addr>/decompiled/{raw.sol,optimized.sol,abi.json}
   - selector匹配：transactions/<tx>/contract_sources/<addr>/selectors_from_trace.json
4) 说明：transactions/<tx>/README.md

用法（从仓库根目录）：
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

from txanalyzer import TransactionTraceAnalyzer
from txanalyzer import TransactionProcessor


def _lower_addr(a: str) -> str:
    return (a or "").lower()


def _extract_selectors_by_to(trace_result: List[Dict[str, Any]]) -> Dict[str, Set[str]]:
    """
    从 trace_transaction 的原始结果中提取 selector（method_id）集合。

    返回：to_address(lowercase) -> set(["0x12345678", ...])
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
                f"--reuse-log 需要 log/ 下已有 tx_trace/tx_contracts/tx_report 文件（tx_short={tx_short}），但未找到。"
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

    # 导出 opcode
    paths = {}
    opcode_error: str = ""
    if not args.skip_opcode:
        try:
            opcode_dir = tx_dir / "opcode"
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
            print(f"警告：opcode 导出失败（将继续生成其余产物）：{opcode_error}")

    # selector → signature 映射
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

    # 生成交易目录说明 README
    readme = f"""## 交易产物目录

- **network**: `{network}`
- **tx_hash**: `{tx}`
- **generated_at**: `{ts}`

### 目录结构

- `trace/`
  - `transaction_info.json`: 交易基本信息
  - `<trace_index>_<trace_address...>.json`: 单条调用记录
    - **顺序**: `trace_index`
    - **深度**: `trace_address` 数组长度（越长越深）
- `contracts/`
  - `<address>.json`: 合约信息（含是否开源、ABI、是否反编译成功等）
- `contract_sources/`
  - `<address>/`: 该地址的源码/反编译/selector映射
    - `__index__.txt`（若开源导出成功）
    - `*.sol` / `*.abi.json`（若开源）
    - `decompiled/`（若无源码且反编译成功）
      - `raw.sol`
      - `optimized.sol`（如无AI环境变量则可能等于 raw）
      - `abi.json`
    - `selectors_from_trace.json`: 从本交易 trace 中出现的 selector → 签名映射（openchain）
- `opcode/`
  - `tx_assembly_{{tx_short}}_*.json`: `debug_traceTransaction` structLogs（指令级）
  - `tx_assembly_{{tx_short}}_*.asm.txt`: 人类可读 opcode 列表
  - 注：如 RPC 不支持或执行超时，此目录可能缺失；可用 `--skip-opcode` 跳过，或增大 `--timeout` 重试。

### 生成来源（log/ 中的原始文件）

- `{trace_json}`
- `{calls_csv}`
- `{contracts_json}`
- `{report_path}`

### 重新生成

```bash
source venv/bin/activate
python scripts/pull_artifacts.py --network {network} --tx {tx}
```
"""
    (tx_dir / "README.md").write_text(readme, encoding="utf-8")

    analyzer._save_function_signature_cache()

    print("完成。交易目录：", tx_dir)
    if paths:
        print("opcode 输出：", paths)
    if opcode_error:
        print("opcode 导出错误：", opcode_error)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
