# TxAnalyzer

Blockchain attack transaction analysis tool. Pull transaction artifacts (trace, contract source code, opcode) in one command, then automatically analyze attack transaction root causes via AI Agent.

**Online version: [txanalyzer.xyz](https://txanalyzer.xyz/)**

## Benchmark

Tested on 18 real-world DeFi hack events from [DeFiHackLabs](https://github.com/SunWeb3Sec/DeFiHackLabs), comparing AI-generated root cause analysis against human expert reports:

![AI RCA vs Human RCA Benchmark](assets/benchmark.png)

### Recommended Models

| Rank | Model | Notes |
|------|-------|-------|
| 1 | **Claude Opus 4.6** | Best overall; deepest reasoning and trust boundary penetration |
| 2 | GPT xhigh | Near-Opus quality; strong on complex multi-step exploits |
| 3 | GPT high | Good balance of cost and accuracy |
| 4 | GPT (standard) | Baseline; may miss subtle write-object causality |

## Quick Start

```bash
source venv/bin/activate
pip install -r requirements.txt
python scripts/pull_artifacts.py --network bsc --tx 0xYOUR_TX_HASH
```

After pulling artifacts, start a conversation in Cursor:

> "Analyze this attack transaction 0xYOUR_TX_HASH on bsc"

The Agent will strictly follow the methodology to analyze and output `transactions/<tx>/analysis/result.md`.

## Prerequisites: `config.json`

Copy `config_template.json` to `config.json` and fill in your API keys:

```json
{
  "networks": {
    "bsc": {
      "name": "BSC Mainnet",
      "rpc_url": "https://bnb-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_API_KEY",
      "etherscan_api_key": "YOUR_BSCSCAN_API_KEY",
      "etherscan_base_url": "https://api.etherscan.io/v2/api",
      "chain_id": 56
    }
  },
  "default_network": "bsc"
}
```

## Project Structure

```
TxAnalyzer/
├── docs/                  # Analysis methodology & specifications (core)
│   ├── ATTACK_TX_ANALYSIS_METHODOLOGY.md   # 6-phase workflow
│   ├── ATTACK_TX_ANALYSIS_SPEC.md          # Mandatory gates & stop conditions
│   ├── ATTACK_TX_ANALYSIS_MODULES.md       # Modular checklists
│   └── ATTACK_TX_ANALYSIS_DEEP_DIVE.md     # Deep root cause investigation
├── txanalyzer/            # Core analysis library
│   ├── tx_analyzer.py     # TransactionTraceAnalyzer
│   ├── transaction_processor.py
│   └── heimdall_api.py
├── scripts/               # CLI entry scripts
│   ├── pull_artifacts.py  # Pull transaction artifacts
│   ├── backfill_opcodes.py
│   ├── cleanup.py         # Clean up transaction artifacts
│   └── decompile.py       # Contract decompilation
├── .cursor/               # Cursor AI Agent configuration
│   ├── skills/attack-tx-analysis/  # Analysis workflow orchestration Skill
│   └── rules/                      # Methodology enforcement Rule
├── assets/                # Images and static assets
│   └── benchmark.png      # AI vs Human RCA benchmark
├── config.json            # Network configuration (not committed)
├── config_template.json   # Configuration template
└── requirements.txt
```

## CLI Usage

### Pull Transaction Artifacts

```bash
python scripts/pull_artifacts.py --network bsc --tx 0x...
```

Common parameters:
- `--tx`: Required, transaction hash
- `--network`: Optional, defaults to `bsc`
- `--timeout`: Optional, defaults to `120`
- `--skip-opcode`: Skip `debug_traceTransaction`
- `--reuse-log`: Reuse existing log file

### Clean Up Transaction Artifacts

```bash
python scripts/cleanup.py --tx 0x... --dry-run
python scripts/cleanup.py --tx 0x...
```

### Contract Decompilation

```bash
python scripts/decompile.py
```

## AI Analysis Workflow

The analysis is driven by Cursor Agent, strictly following 4 methodology documents:

1. **Pull Artifacts**: `pull_artifacts.py` fetches trace / contract source code / opcode / selector mappings
2. **Phase 1-6 Analysis**: Follows the 6-phase workflow in `ATTACK_TX_ANALYSIS_METHODOLOGY.md`
3. **SPEC Self-Check**: After each phase, validates against gates and constraints in `ATTACK_TX_ANALYSIS_SPEC.md`
4. **Module Triggers**: Executes checklists when trigger conditions in `ATTACK_TX_ANALYSIS_MODULES.md` are met
5. **Deep Dive**: After Phase 6, penetrates trust boundaries per `ATTACK_TX_ANALYSIS_DEEP_DIVE.md`

## Claude Code Skill Usage

This project ships with a Claude Code skill (`CLAUDE.md`) that turns Claude into an end-to-end attack transaction analyst. When loaded, Claude will:

1. **Pull artifacts** — run `pull_artifacts.py` to fetch trace, contract source code, opcodes, and selector mappings
2. **Read all 4 methodology docs** — `METHODOLOGY`, `SPEC`, `MODULES`, `DEEP_DIVE` (cannot be skipped)
3. **Execute 6-phase analysis** — Triage → Graphs → Hypotheses → Evidence → Closure → Deliverable, with SPEC self-check after each phase
4. **Deep root cause drilling** — penetrate every trust boundary and audit each validation function line-by-line
5. **Output `result.md`** — one-sentence root cause, evidence chain, reproduction steps, fix recommendations, confidence rating

### Quick Start with Claude Code

```bash
# 1. Ensure config.json is set up with your API keys
cp config_template.json config.json
# Edit config.json to fill in Alchemy RPC URL and Etherscan API Key

# 2. Start Claude Code from the project root
claude

# 3. Ask Claude to analyze a transaction
> Analyze attack transaction 0xYOUR_TX_HASH on bsc
```

Claude will automatically activate the virtual environment, pull artifacts, read the methodology, and produce an audit-grade report at `transactions/<tx>/analysis/result.md`.

### Key Constraints Enforced by the Skill

| Constraint | Description |
|------------|-------------|
| Write-object-first Gate | Must verify "whose ledger was credited" before classifying as Read-type |
| Victim-first Gate | Must draw victim subgraph when third-party extraction is detected |
| Falsification order | Write before Read — skipping is prohibited |
| Trust boundary penetration | Every validation function on the attack path must be audited line-by-line |
| Module triggers | When trigger conditions are met (e.g., batch liquidation, ERC4626 manipulation), the corresponding module checklist must be executed |
| Confidence gate | `high` requires ≥1 write-object evidence; `low` if no gate passed |

### Supported Networks

| Network | Config Key |
|---------|-----------|
| BSC Mainnet | `bsc` (default) |
| Ethereum Mainnet | `eth` |
| Sepolia Testnet | `sepolia` |
| Polygon Amoy | `polygon_amoy` |

## Output Location

After execution, artifacts are generated in: `transactions/<tx_hash>/` (the directory includes a `README.md` explaining each subdirectory).

Analysis result: `transactions/<tx_hash>/analysis/result.md`
