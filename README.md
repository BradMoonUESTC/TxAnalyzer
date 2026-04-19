# TxAnalyzer

Blockchain attack transaction analysis tool. Pull transaction artifacts in one command, then automatically analyze attack transaction root causes via AI Agent. EVM networks include trace / contract source code / opcode; Solana includes the richest standard-RPC transaction / instruction / account / program artifacts available from RPC.

**Online version: [txanalyzer.xyz](https://txanalyzer.xyz/)**

## Install as Agent Skill

This project follows the [Agent Skills](https://agentskills.io/) open standard and works with **Claude Code**, **Cursor**, **Codex**, **Windsurf**, and [40+ more agents](https://github.com/vercel-labs/skills#supported-agents).

```bash
# Install to your current project (symlink)
npx skills add xueyue/TxAnalyzer

# Install globally (available across all projects)
npx skills add xueyue/TxAnalyzer -g

# Install to a specific agent
npx skills add xueyue/TxAnalyzer -a claude-code
npx skills add xueyue/TxAnalyzer -a cursor
```

After installation, ask your agent:

> "Analyze attack transaction 0xYOUR_TX_HASH on bsc"

The agent will follow the 6-phase methodology, Deep Dive, and post-Deep-Dive PoC/RPC replay workflow to pull artifacts, analyze root cause, and produce `transactions/<tx>/analysis/result.md`.

## Benchmark

Tested on 18 real-world DeFi hack events from [DeFiHackLabs](https://github.com/SunWeb3Sec/DeFiHackLabs), comparing AI-generated root cause analysis against human expert reports:

![AI RCA vs Human RCA Benchmark](assets/benchmark.png)

### Recommended Models

| Rank | Model | Notes |
|------|-------|-------|
| 1 | **Claude Opus 4.6** | Best overall; deepest reasoning and trust boundary penetration |
| 2 | GPT-5.4 xhigh | Near-Opus quality; strong on complex multi-step exploits |
| 3 | GPT-5.4 high | Good balance of cost and accuracy |
| 4 | GPT-5.4 | Baseline; may miss subtle write-object causality |

## Quick Start

```bash
source venv/bin/activate
pip install -r requirements.txt
python scripts/pull_artifacts.py --network bsc --tx 0xYOUR_TX_HASH
python scripts/pull_artifacts.py --network solana --tx YOUR_SOLANA_SIGNATURE
```

After pulling artifacts, start a conversation in Cursor:

> "Analyze this attack transaction 0xYOUR_TX_HASH on bsc"

The Agent will strictly follow the methodology to analyze and output `transactions/<tx>/analysis/result.md`, including the reverse-engineering / PoC / RPC replay sections.

## Prerequisites: `config.json`

Copy `config_template.json` to `config.json` and fill in your RPC/API keys:

```json
{
  "networks": {
    "bsc": {
      "name": "BSC Mainnet",
      "rpc_url": "https://bnb-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_API_KEY",
      "etherscan_api_key": "YOUR_BSCSCAN_API_KEY",
      "etherscan_base_url": "https://api.etherscan.io/v2/api",
      "chain_id": 56
    },
    "solana": {
      "name": "Solana Mainnet",
      "rpc_url": "https://solana-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_API_KEY"
    }
  },
  "default_network": "bsc"
}
```

## Project Structure

```
TxAnalyzer/
├── SKILL.md               # Agent Skill entry point (agentskills.io standard)
├── CLAUDE.md              # Backward-compatible project memory for Claude Code
├── docs/                  # Analysis methodology & specifications (core)
│   ├── ATTACK_TX_ANALYSIS_METHODOLOGY.md   # 6-phase workflow
│   ├── ATTACK_TX_ANALYSIS_SPEC.md          # Mandatory gates & stop conditions
│   ├── ATTACK_TX_ANALYSIS_MODULES.md       # Modular checklists
│   ├── ATTACK_TX_ANALYSIS_DEEP_DIVE.md     # Deep root cause investigation
│   ├── ATTACK_TX_ANALYSIS_POC_REPLAY.md    # Post-deep-dive reverse engineering / PoC / RPC replay
│   ├── ATTACK_TX_ANALYSIS_FORK_HARNESS.md  # Foundry + anvil tx-prestate fork harness
│   └── ATTACK_TX_ANALYSIS_RISK_BOUND.md    # Read-only risk upper bound evaluation
├── txanalyzer/            # Core analysis library
│   ├── tx_analyzer.py     # TransactionTraceAnalyzer
│   ├── transaction_processor.py
│   └── heimdall_api.py
├── scripts/               # CLI entry scripts
│   ├── pull_artifacts.py  # Pull transaction artifacts
│   ├── pull_solana_artifacts.py
│   ├── backfill_opcodes.py
│   ├── cleanup.py         # Clean up transaction artifacts
│   └── decompile.py       # Contract decompilation
├── log/                   # Caches (function signature cache)
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
python scripts/pull_artifacts.py --network solana --tx <SOLANA_SIGNATURE>
```

Common parameters:
- `--tx`: Required, transaction hash
- `--network`: Optional, defaults to `bsc`; use `solana` for Solana signatures
- `--timeout`: Optional, defaults to `120`
- `--skip-opcode`: Skip `debug_traceTransaction` for EVM; Solana has no opcode trace via standard RPC
- `--reuse-log`: Reuse existing EVM log file

When `--network solana` is used, artifacts are organized under `transactions/<signature>/` and include:
- `trace/`: `getTransaction` raw payloads, parsed instructions, logs, block/status, lamport/token balance diffs
- `accounts/`: every touched account as both `base64` and `jsonParsed`
- `contracts/` + `contract_sources/`: invoked program summaries, ProgramData, executable bytes when available
- `opcode/`: capability notes explaining why standard Solana RPC cannot provide opcode-level traces

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

The analysis is driven by Cursor Agent, strictly following 4 pre-analysis methodology documents plus 3 mandatory post-Deep-Dive reconstruction documents:

1. **Pull Artifacts**: `pull_artifacts.py` fetches chain-specific artifacts. EVM: trace / contract source / opcode / selector mappings. Solana: transaction/meta payloads, instructions, logs, account snapshots, invoked program metadata/binaries.
2. **Phase 1-6 Analysis**: Follows the 6-phase workflow in `ATTACK_TX_ANALYSIS_METHODOLOGY.md`
3. **SPEC Self-Check**: After each phase, validates against gates and constraints in `ATTACK_TX_ANALYSIS_SPEC.md`
4. **Module Triggers**: Executes checklists when trigger conditions in `ATTACK_TX_ANALYSIS_MODULES.md` are met
5. **Deep Dive**: After Phase 6, penetrates trust boundaries per `ATTACK_TX_ANALYSIS_DEEP_DIVE.md`
6. **PoC / RPC Replay**: Reverse-engineers the attacker contract, generates a unified PoC, and replays at the attack-block RPC context per `ATTACK_TX_ANALYSIS_POC_REPLAY.md`
7. **Fork Harness**: Builds a Foundry + `anvil --fork-transaction-hash` harness with blocker tests, seeded simulation, and exact-prestate replay (with `==` assertions) per `ATTACK_TX_ANALYSIS_FORK_HARNESS.md`
8. **Risk Upper Bound**: Read-only defensive evaluation of `min(objectBalance, accumulatorRemaining)` at the tx prestate per `ATTACK_TX_ANALYSIS_RISK_BOUND.md`

A reference end-to-end walkthrough lives in [`case_studies/tx-0x767d8a0f-lista-flap/`](case_studies/tx-0x767d8a0f-lista-flap/README.md).

## Claude Code Skill Usage

This project ships with a Claude Code skill (`CLAUDE.md`) that turns Claude into an end-to-end attack transaction analyst. When loaded, Claude will:

1. **Pull artifacts** — run `pull_artifacts.py` to fetch chain-specific artifacts
2. **Read all 7 methodology docs** — `METHODOLOGY`, `SPEC`, `MODULES`, `DEEP_DIVE`, `POC_REPLAY`, `FORK_HARNESS`, `RISK_BOUND` (cannot be skipped)
3. **Execute 6-phase analysis** — Triage → Graphs → Hypotheses → Evidence → Closure → Deliverable, with SPEC self-check after each phase
4. **Deep root cause drilling** — penetrate every trust boundary and audit each validation function line-by-line
5. **Post-deep-dive exploit reconstruction** — reverse-engineer the attacker contract, generate a unified PoC
6. **Foundry + anvil replay** — build the tx-prestate fork harness and assert deterministic on-fork outputs with `==`
7. **Risk upper bound evaluation** — read-only `min(balance, accumulatorRemaining)` at the tx prestate; compare to actual drain
8. **Output `result.md`** — one-sentence root cause, evidence chain, deep root cause, PoC, replay evidence, risk upper bound, fix recommendations, confidence rating

### Quick Start with Claude Code

```bash
# 1. Ensure config.json is set up with your API keys
cp config_template.json config.json
# Edit config.json to fill in the RPC URL; EVM networks also require Etherscan-compatible API keys

# 2. Start Claude Code from the project root
claude

# 3. Ask Claude to analyze a transaction
> Analyze attack transaction 0xYOUR_TX_HASH on bsc
```

Claude will automatically activate the virtual environment, pull artifacts, read the methodology, and produce an audit-grade report at `transactions/<tx>/analysis/result.md`, including Deep Root Cause, attacker-contract PoC, attack-block RPC replay, and risk upper bound evaluation.

For Solana, the artifact puller is supported through the same `pull_artifacts.py` entrypoint, but the current deep exploit methodology and replay stack remain EVM-first because they rely on EVM traces/opcodes/Foundry semantics.

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
| Solana Mainnet | `solana` |

## Output Location

After execution, artifacts are generated in: `transactions/<tx_hash>/` (the directory includes a `README.md` explaining each subdirectory).

Analysis result: `transactions/<tx_hash>/analysis/result.md`

## Donate

If this project helps you, consider buying me a coffee:
7zYKQuRQWuNZLiYpxPB2VcpciiYyMKgjdDvohdHoQm3e（solana）
**`0x8625c682ac045652a95dd0cd6dea8e47e3cfb175`** (All EVM chains)
