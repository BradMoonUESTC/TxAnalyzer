# TxAnalyzer — Attack Transaction Analysis

This project follows the [Agent Skills](https://agentskills.io/) open standard.
All analysis instructions, mandatory rules, gates, and workflow are defined in [SKILL.md](SKILL.md).

When a user provides a transaction hash for attack analysis, invoke the `attack-tx-analysis` skill
(or read SKILL.md directly) and follow its instructions strictly.

## Quick Reference

- **Pull artifacts**: `python scripts/pull_artifacts.py --network <NET> --tx <TX>`
- **Config**: copy `config_template.json` → `config.json`, fill in API keys
- **Methodology docs**: `docs/ATTACK_TX_ANALYSIS_*.md` (all 4 must be read before analysis)
- **Output**: `transactions/<tx>/analysis/result.md`
