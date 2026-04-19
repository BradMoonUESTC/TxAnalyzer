# TxAnalyzer — Attack Transaction Analysis

This project follows the [Agent Skills](https://agentskills.io/) open standard.
All analysis instructions, mandatory rules, gates, and workflow are defined in [SKILL.md](SKILL.md).

When a user provides a transaction hash for attack analysis, invoke the `attack-tx-analysis` skill
(or read SKILL.md directly) and follow its instructions strictly, including the
post-deep-dive reverse-engineering / PoC / Foundry fork replay / risk upper bound stages.

## Quick Reference

- **Pull artifacts**: `python scripts/pull_artifacts.py --network <NET> --tx <TX>`
- **Config**: copy `config_template.json` → `config.json`, fill in API keys
- **Methodology docs**: 4 pre-analysis docs (`METHODOLOGY`/`SPEC`/`MODULES`/`DEEP_DIVE`) + 3 post-analysis docs (`POC_REPLAY`/`FORK_HARNESS`/`RISK_BOUND`) under `docs/` — all mandatory
- **Replay tooling**: Foundry (`forge`/`anvil`/`cast`) + `BSC_RPC_URL` in env
- **Output**: `transactions/<tx>/analysis/result.md` (Phase 1–6 + Deep Root Cause + PoC + RPC Replay + Risk Upper Bound + Confidence)

Notes:
- EVM networks: pull trace / contract source / decompilation / opcode / selector mappings
- Solana: same `pull_artifacts.py` entrypoint now pulls transaction/meta payloads, outer/inner instructions, logs, touched-account snapshots, and invoked-program metadata/binaries
- The deep exploit-analysis workflow in `SKILL.md` is still EVM-first; do not assume Solana has `debug_traceTransaction`, opcode traces, or RPC source-code retrieval
