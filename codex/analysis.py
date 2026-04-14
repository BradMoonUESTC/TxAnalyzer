#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
全流程：
1) 运行 scripts/pull_artifacts.py 拉取交易产物（包含 opcode + 反编译）
2) 准备 Codex workspace = transactions/
   - 复制 docs/ATTACK_TX_ANALYSIS_SPEC.md / docs/ATTACK_TX_ANALYSIS_METHODOLOGY.md 到 transactions/
   - （可选）把 output/local/<tx>/ 同步到 transactions/<tx>/output_local/ 便于在 workspace 内引用
3) 调用 Codex CLI 对该交易目录做严格分析，并把最终结果落盘到 transactions/<tx>/analysis/
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
from pathlib import Path

from codex.client import ask_codex, CodexError


REPO_ROOT = Path(__file__).resolve().parents[1]
TRANSACTIONS_DIR = (REPO_ROOT / "transactions").resolve()


def _run_pull(*, network: str, tx: str, timeout_sec: int) -> None:
    cmd = [
        "python",
        str((REPO_ROOT / "scripts" / "pull_artifacts.py").resolve()),
        "--network",
        network,
        "--tx",
        tx,
        "--timeout",
        str(timeout_sec),
    ]
    subprocess.run(cmd, cwd=str(REPO_ROOT), check=True)


def _sync_analysis_docs_to_transactions() -> None:
    """
    把方法论与 SPEC 放进 transactions workspace。
    这样 Codex 的 --cd 指向 transactions/ 时仍然能读取两份 md。
    """
    TRANSACTIONS_DIR.mkdir(parents=True, exist_ok=True)

    for name in (
        "ATTACK_TX_ANALYSIS_SPEC.md",
        "ATTACK_TX_ANALYSIS_METHODOLOGY.md",
        "ATTACK_TX_ANALYSIS_MODULES.md",
        "ATTACK_TX_ANALYSIS_DEEP_DIVE.md",
    ):
        src = REPO_ROOT / "docs" / name
        dst = TRANSACTIONS_DIR / name
        if src.exists():
            shutil.copy2(src, dst)


def _sync_output_local_into_tx_workspace(tx: str) -> None:
    """
    可选同步：把 output/local/<tx>/ 拷贝到 transactions/<tx>/output_local/
    目的：Codex workspace = transactions/ 时仍可访问 "output/local" 的反编译结果。

    注：实际分析所需的 decompiled raw/optimized/abi 已由 pull_tx_artifacts
    拷贝进 transactions/<tx>/contract_sources/<addr>/decompiled/。
    """
    src_dir = (REPO_ROOT / "output" / "local" / tx).resolve()
    if not src_dir.exists() or not src_dir.is_dir():
        return

    tx_dir = (TRANSACTIONS_DIR / tx).resolve()
    if not tx_dir.exists():
        return

    dst_dir = tx_dir / "output_local"
    if dst_dir.exists():
        shutil.rmtree(dst_dir)
    shutil.copytree(src_dir, dst_dir)


def _build_prompt(*, tx: str) -> str:
    """
    注意：Codex workspace 会设置为 transactions/。
    所以这里所有路径都应使用 workspace 内相对路径：<tx>/trace, <tx>/opcode, ...
    """
    tx_dir = f"{tx}"
    return f"""分析一下这个交易：`{tx_dir}`
他是一个攻击，分析一下真正的 root cause。

## 第一阶段：主分析

根据 `ATTACK_TX_ANALYSIS_METHODOLOGY.md` 逐步进行分析（阶段 1→6），
但是每分析一步都要回过头来看一下之前的分析是否违反了 `ATTACK_TX_ANALYSIS_SPEC.md`。
如果命中 `ATTACK_TX_ANALYSIS_MODULES.md` 中的任何模块触发条件，必须执行对应模块的检查清单。

必须严格遵循 `ATTACK_TX_ANALYSIS_SPEC.md` 中的要求，不能有一点违反。

## 第二阶段：深层 Root Cause 挖掘

完成阶段 1→6 后，**立即严格按照 `ATTACK_TX_ANALYSIS_DEEP_DIVE.md` 执行深层 root cause 挖掘**。

核心要求：
- 画出从攻击入口到最终写入的完整信任边界链
- **逐个打开每个信任边界的校验函数完整源码**，逐行审查（不允许跳过）
- 即使阶段 3→6 的解释"已经能闭环"，仍必须检查所有更底层的校验函数
- 对 proof verification / Merkle验证 / 签名校验等密码学函数，必须检查输入校验、边界条件、绑定关系
- 最终确定**最深层的不可再分解的代码缺陷**，如果与阶段 6 结论不同，必须修正

## 你可以使用的资源

- 合约源码：`{tx_dir}/contract_sources`
- 交易 opcode：`{tx_dir}/opcode`
- 交易 trace：`{tx_dir}/trace`（区分了深度和顺序）
- 未开源合约反编译结果：`{tx_dir}/output_local`（如果该目录存在；否则以 contract_sources 下 decompiled 为准）

## 输出要求

- 按方法论阶段推进（阶段 1→6），每个阶段末尾做一次 SPEC 自检
- 必须执行 Write-object-first Gate（如触发条件命中）
- 最终必须给出 Write→Read→Trigger→Profit 闭环与置信度（low/medium/high）
- 阶段 6 之后必须有"深层 Root Cause 分析"章节（信任边界链 + 逐一审查 + 最深层结论）
"""


def main() -> int:
    p = argparse.ArgumentParser(description="Pull tx artifacts then analyze by Codex (workspace=transactions/).")
    p.add_argument("--network", required=True)
    p.add_argument("--tx", required=True)
    p.add_argument("--timeout-sec", type=int, default=120)
    p.add_argument("--pull-only", action="store_true", help="Only pull artifacts, skip Codex analysis.")

    p.add_argument("--codex-model", default="gpt-5.2")
    p.add_argument("--codex-reasoning-effort", default="high", choices=["low", "medium", "high"])
    p.add_argument("--codex-stream", action="store_true", default=True)
    p.add_argument("--codex-no-stream", action="store_false", dest="codex_stream")

    p.add_argument("--codex-ask-for-approval", default="never", choices=["never", "auto", "always"])

    args = p.parse_args()

    tx = args.tx.strip()
    network = args.network.strip()

    # 1) Pull
    print("[STAGE] pull:start")
    _run_pull(network=network, tx=tx, timeout_sec=args.timeout_sec)
    print("[STAGE] pull:end")

    # 2) Prepare workspace = transactions/
    print("[STAGE] workspace:start")
    _sync_analysis_docs_to_transactions()
    _sync_output_local_into_tx_workspace(tx)
    print("[STAGE] workspace:end")

    if args.pull_only:
        print("[完成] pull-only：已生成 transactions 产物，未运行 Codex。")
        return 0

    # 3) Run Codex analysis (read-only)
    tx_dir = (TRANSACTIONS_DIR / tx).resolve()
    tx_analysis_dir = (tx_dir / "analysis").resolve()
    tx_analysis_dir.mkdir(parents=True, exist_ok=True)

    output_path = tx_dir / "result.md"
    last_msg_path = tx_analysis_dir / "codex_last_message.txt"

    prompt = _build_prompt(tx=tx)

    try:
        print("[STAGE] codex:start")
        res = ask_codex(
            project_path=str(TRANSACTIONS_DIR),
            question=prompt,
            model=args.codex_model,
            reasoning_effort=args.codex_reasoning_effort,
            auth_method="apikey",
            sandbox="read-only",
            ask_for_approval=args.codex_ask_for_approval,
            output_last_message_path=str(output_path),
            stream_output=args.codex_stream,
            use_json_events=False,
        )
        print("[STAGE] codex:end")
    except CodexError as e:
        print(f"[ERROR] Codex 执行失败：{e}")
        return 2

    output_path.write_text(res.final_text.rstrip() + "\n", encoding="utf-8")
    try:
        last_msg_path.write_text(res.final_text.rstrip() + "\n", encoding="utf-8")
    except Exception:
        pass

    print(f"\n[写入完成] {output_path}")
    print(f"[兜底备份] {last_msg_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
