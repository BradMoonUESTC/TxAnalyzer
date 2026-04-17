---
name: attack-tx-analysis
description: >-
  Analyze blockchain attack transactions end-to-end: pull artifacts (trace,
  contract source code, opcodes, selector mappings), decompile unverified
  contracts via Heimdall, then perform systematic 6-phase root cause analysis
  with deep trust boundary drilling, attacker-contract reverse engineering,
  unified PoC generation, Foundry + anvil tx-prestate fork replay with
  deterministic assertions, and read-only risk upper bound evaluation to
  produce audit-grade reports. Use when the user provides a transaction hash
  and asks to analyze an exploit, attack, hack, or suspicious blockchain
  transaction.
---

# Attack Transaction Analysis

Pull transaction artifacts → analyze root cause following strict methodology → produce audit-grade reports.

## Prerequisites

1. Install Python dependencies:

```bash
pip install -r ${CLAUDE_SKILL_DIR}/requirements.txt
```

2. Copy `config_template.json` to `config.json` at the project working directory and fill in API keys (Alchemy RPC URL + Etherscan/BscScan API key). If `config.json` is missing, prompt the user.

3. **Heimdall** (optional, for decompiling unverified contracts): binary expected at `~/.bifrost/bin/heimdall`. Install via `curl -L https://bifrost.sh | bash && bifrost --install heimdall`.

4. **Foundry** (required for Fork Harness + Risk Upper Bound stages): `forge`, `anvil`, `cast` must be on `$PATH`. Install via `curl -L https://foundry.paradigm.xyz | bash && foundryup`.

5. **Shell env** (required for Fork Harness): `BSC_RPC_URL` (and equivalents for other networks, e.g. `ETH_RPC_URL`) must be exported before running `anvil --fork-url "$BSC_RPC_URL" ...` and `forge test`. Value should match the RPC URL in `config.json`.

Supported networks: `bsc` (default), `eth`, `sepolia`, `polygon_amoy`.

## Core Commands

### Artifact & analysis tooling (Python)

```bash
python ${CLAUDE_SKILL_DIR}/scripts/pull_artifacts.py --network <NET> --tx <TX_HASH> [--timeout 120] [--skip-opcode] [--reuse-log]
python ${CLAUDE_SKILL_DIR}/scripts/cleanup.py --tx <TX_HASH> [--dry-run]
python ${CLAUDE_SKILL_DIR}/scripts/decompile.py
python ${CLAUDE_SKILL_DIR}/scripts/backfill_opcodes.py [--ctf ctf] [--timeout 600]
```

### Replay harness tooling (Foundry + anvil)

Used by the Fork Harness and Risk Upper Bound stages. Full recipe lives in `docs/ATTACK_TX_ANALYSIS_FORK_HARNESS.md`.

```bash
# 1. Pin a local node to the exact tx prestate (do NOT use vm.createSelectFork(txHash) against BSC remote; see FORK_HARNESS.md)
anvil \
  --fork-url "$BSC_RPC_URL" \
  --fork-transaction-hash <TX_HASH> \
  --port 8546 \
  --timeout 120000 --retries 20 --fork-retry-backoff 1000 --no-rate-limit

# 2. Run the full replay + risk bound test suite
forge test -vv

# 3. Single-purpose runs
forge test --match-test testReplayAttackFromExactTxPrestate -vv
forge test --match-test testRiskUpperBoundAtTxPrestate -vv

# 4. Quick on-fork sanity probes
cast chain-id     --rpc-url http://127.0.0.1:8546
cast block-number --rpc-url http://127.0.0.1:8546
cast tx           --rpc-url http://127.0.0.1:8546 <TX_HASH>
```

### `pull_artifacts.py` Pipeline

1. `trace_transaction` RPC → parse call tree → save `tx_trace_*.json` + `tx_calls_*.csv`
2. Per contract: fetch source/ABI from Etherscan → export `.sol`; decompile via Heimdall if unverified
3. `TransactionProcessor` splits into `transactions/<tx>/trace/`, `contracts/`, `contract_sources/`
4. `debug_traceTransaction` → export to `transactions/<tx>/opcode/` (`--skip-opcode` to skip)
5. Extract selectors → query function signatures from openchain.xyz → `selectors_from_trace.json`
6. Generate `transactions/<tx>/README.md`

## Artifact Directory Structure

```
transactions/<tx_hash>/
├── README.md
├── tx_report.txt
├── analysis/
│   └── result.md
├── trace/
│   ├── transaction_info.json
│   ├── <index>_d<depth>_*.json
│   └── __files_index__.json
├── contracts/
│   └── <addr>.json
├── contract_sources/
│   └── <addr>/
│       ├── __index__.txt
│       ├── *.sol / *.abi.json
│       ├── decompiled/
│       │   ├── raw.sol
│       │   ├── optimized.sol
│       │   └── abi.json
│       └── selectors_from_trace.json
└── opcode/
    ├── tx_assembly_*.json
    └── tx_assembly_*.asm.txt
```

## Analysis Workflow

When a user provides a transaction hash requesting attack analysis, execute strictly in this order.

### Step 1: Pull Artifacts

```bash
python ${CLAUDE_SKILL_DIR}/scripts/pull_artifacts.py --network <NET> --tx <TX>
```

### Step 2: Read Methodology (must not skip, must not partially read)

Before analysis, **all 7 analysis documents must be read in full**. SPEC has the highest priority. After Deep Dive, the PoC/Replay, Fork Harness, and Risk Upper Bound documents must also be executed in order.

| Document | Path | Responsibility | Priority |
|----------|------|----------------|----------|
| **METHODOLOGY** | [docs/ATTACK_TX_ANALYSIS_METHODOLOGY.md](docs/ATTACK_TX_ANALYSIS_METHODOLOGY.md) | 6-phase workflow + core principles + LLM strategies | Baseline |
| **SPEC** | [docs/ATTACK_TX_ANALYSIS_SPEC.md](docs/ATTACK_TX_ANALYSIS_SPEC.md) | Mandatory gates, evidence thresholds, stop conditions | **Highest** |
| **MODULES** | [docs/ATTACK_TX_ANALYSIS_MODULES.md](docs/ATTACK_TX_ANALYSIS_MODULES.md) | Modular checklists (mandatory when trigger conditions met) | On-demand |
| **DEEP DIVE** | [docs/ATTACK_TX_ANALYSIS_DEEP_DIVE.md](docs/ATTACK_TX_ANALYSIS_DEEP_DIVE.md) | Deep root cause drilling | Mandatory after Phase 6 |
| **POC / REPLAY** | [docs/ATTACK_TX_ANALYSIS_POC_REPLAY.md](docs/ATTACK_TX_ANALYSIS_POC_REPLAY.md) | Attacker-contract reverse engineering + unified PoC + RPC replay | Mandatory after Deep Dive |
| **FORK HARNESS** | [docs/ATTACK_TX_ANALYSIS_FORK_HARNESS.md](docs/ATTACK_TX_ANALYSIS_FORK_HARNESS.md) | Concrete Foundry + anvil tx-prestate harness: layout, blocker tests, deterministic assertions | Mandatory when PoC/Replay requires executable evidence |
| **RISK BOUND** | [docs/ATTACK_TX_ANALYSIS_RISK_BOUND.md](docs/ATTACK_TX_ANALYSIS_RISK_BOUND.md) | Defensive read-only risk upper bound evaluation at the tx prestate | Mandatory after Fork Harness replay passes |

### Step 3: Execute Analysis Strictly Phase by Phase

| Phase | Task | Required on Completion |
|-------|------|----------------------|
| 1 Triage | Read trace; identify participants / asset flows / anomalies / phase labels / accumulator buckets | SPEC self-check |
| 2 Graphs | Fund flow graph + control flow graph + Phase Map; draw Victim Subgraph + Degradation Chain when victims exist | SPEC self-check |
| 3 Hypotheses | 2-4 competing explanations per anomaly + shortest falsification; must execute when Gate is triggered | SPEC self-check + check modules |
| 4 Evidence | Advance along evidence pyramid (state writes > reproducible values > events > source code > intuition) | SPEC self-check |
| 5 Closure | Write→Read→Trigger→Profit closed loop; confidence gate | SPEC self-check |
| 6 Deliverable | One-sentence root cause + evidence + reproduction steps + fix | SPEC self-check |
| **Deep Dive** | **Trust boundary chain → open and audit each validation function's source → deepest root cause** | **Must not skip** |
| **PoC / Replay** | **Read all tx artifacts including `result.md` → reverse engineer attacker contract → generate unified PoC → replay via RPC at attack-block context** | **Must not skip** |
| **Fork Harness** | **Build Foundry + anvil tx-prestate harness per `ATTACK_TX_ANALYSIS_FORK_HARNESS.md`; encode blocker tests, seeded simulation, and exact-prestate replay with `==` assertions** | **Must not skip when PoC/Replay produces runnable code** |
| **Risk Upper Bound** | **Per `ATTACK_TX_ANALYSIS_RISK_BOUND.md`, compute `min(objectBalance, accumulatorRemaining)` at the tx prestate and compare to the actual drain (read-only)** | **Must not skip after Fork Harness passes** |

### Available Resources During Analysis

| Resource | Path | Purpose |
|----------|------|---------|
| Contract source code | `transactions/<tx>/contract_sources/` | Verified source or decompiled code |
| Trace | `transactions/<tx>/trace/` | Call records split by depth/order |
| Opcode | `transactions/<tx>/opcode/` | Instruction-level structLogs |
| Contract info | `transactions/<tx>/contracts/` | Per-address metadata |
| Selector mapping | `transactions/<tx>/contract_sources/<addr>/selectors_from_trace.json` | Function signature lookup |
| Summary report | `transactions/<tx>/tx_report.txt` | Transaction overview |
| Prior analysis result | `transactions/<tx>/analysis/result.md` | Mandatory input to post-deep-dive PoC / replay stage |

### Step 4: Output Results

Write the following into `transactions/<tx>/analysis/result.md`, in this order, with no stage skipped:

1. **Phase 1–6 root cause body** — per `ATTACK_TX_ANALYSIS_METHODOLOGY.md` + `ATTACK_TX_ANALYSIS_SPEC.md` (one-sentence root cause, trigger conditions, participants, Write → Read → Trigger → Profit closed loop, key evidence, minimal reproduction, remediation).
2. **Deep Root Cause Analysis** — per `ATTACK_TX_ANALYSIS_DEEP_DIVE.md` (trust boundary chain, line-by-line audit of each validation function, deepest root cause, revisions to initial analysis).
3. **Reverse Engineering and Unified PoC** — per `ATTACK_TX_ANALYSIS_POC_REPLAY.md` (attack contract set, reverse engineering notes, minimal PoC).
4. **RPC Replay at Attack Block** — per `ATTACK_TX_ANALYSIS_POC_REPLAY.md` + `ATTACK_TX_ANALYSIS_FORK_HARNESS.md` (replay anchor, verdict, replay evidence, exact `forge test` command, on-fork deterministic numbers).
5. **Risk Upper Bound (at tx prestate)** — per `ATTACK_TX_ANALYSIS_RISK_BOUND.md` (measurements, `maxDrainableCap`, drained-in-this-tx, residual, binding constraint, repro pointer).
6. **Confidence** — low / medium / high (= `min(rootCauseConfidence, replayConfidence)` per `ATTACK_TX_ANALYSIS_RISK_BOUND.md`).

Any missing stage must be explicitly labeled `blocked` (and why) instead of silently omitted.

---

## Mandatory Rules (Must Not Violate)

### Gates

**Write-object-first Gate**
- Trigger: settlement object shows extreme readings (reserve=dust, share price spike, health factor collapse) and transfer appears successful
- Question: **"Whose ledger did the transfer actually credit?"**
- Conclusion must be one of two: A (actually credited) / B (overwritten/redirected)
- **Prohibited** from classifying as Read-type until gate is passed

**Victim-first Gate**
- Trigger: third-party liquidation / batch settlement detected
- Question: **"Which third parties had value extracted, and through what mechanism?"**
- Must output: victims list / extraction_action / value_path

**Confidence Gate**
- `high`: ≥1 write-object evidence + complete causal chain
- `medium`: write point located but object/conditions not fully determined
- `low`: Read-type with no gate passed

### Falsification & Evidence

- **Falsification order**: Write before Read; skipping is prohibited
- **Evidence hierarchy**: state writes (SSTORE) > reproducible values > events/logs > source code/decompiled > intuition
- **Negation constraint**: writing "X was not observed" must include search scope + search pattern; otherwise write "X has not been located yet"

### Penetration & Modules

- **Trust boundary penetration**: **every** validation/check function on the attack path must be opened and audited line-by-line. "Already closed the loop" is not a valid reason to skip
- **Module triggers**: when any condition in the table below is met, the full module checklist must be executed

| Module | Trigger Condition |
|--------|------------------|
| A Batch Liquidation | `users_to_liquidate()` returns multiple / batch `liquidate(victim)` |
| B ERC4626 Manipulation | oracle uses `convertToAssets` / share exchange rate mutates within same tx |
| C Large Swap + Mechanism Migration | Banded AMM/LLAMMA + batch liquidation |
| D Swap Discovery | Batch liquidation / oracle input mutation |
| E Pool Coin Resolution | Curve `exchange(i,j)` appears in top swaps |
| F Supply Lever Evidence | Claims `redeem/mint` affects share pricing |
| G Pre-liquidation Migration Evidence | Claims "bands/mechanism caused position migration" |
| H Multi-mechanism Business Chain | Same contract called 3+ times with different function roles / accumulator bucket exists |
| I Cross-chain/Proof Verification | Cross-chain message handler / Merkle/proof verification on the path |

### Stop Conditions (all must be met to converge)

1. ≥1 critical write point located (including write object)
2. All critical anomalies explained by a single causal chain (no residuals)
3. Profit path is reproducibly closed-loop
4. Every validation function on the attack path has been audited (SECURE/VULNERABLE/[OPEN])
5. If Victim-first Gate was triggered: explained "why third parties became extractable"
6. **Deep Root Cause** section appended: deepest trust-boundary defect stated and confirmed against line-by-line audits (per `ATTACK_TX_ANALYSIS_DEEP_DIVE.md`)
7. **Reverse Engineering + Unified PoC** produced with attack contract set, reverse-engineering notes, and a trace-aligned minimal PoC (per `ATTACK_TX_ANALYSIS_POC_REPLAY.md`)
8. **RPC Replay at Attack Block**: `testReplayAttackFromExactTxPrestate` passes against `anvil --fork-transaction-hash`, with `==` assertions on the main settlement-object delta and final profit (per `ATTACK_TX_ANALYSIS_FORK_HARNESS.md`); verdict rendered as `reproduced` / `partially_reproduced` / `blocked`
9. **Risk Upper Bound**: `testRiskUpperBoundAtTxPrestate` passes; `maxDrainableCap`, `drainedInThisTx`, `residualAfterThisTx`, and the binding constraint are recorded in `result.md` (per `ATTACK_TX_ANALYSIS_RISK_BOUND.md`)

### Output Requirements

`result.md` must include **all** of the following sections, in this order. A stage that could not be completed must be explicitly marked `blocked` with a reason — it must not be silently omitted.

- One-sentence root cause + trigger condition + 3-6 key evidence items + 5-10 step minimal reproduction + fix recommendations
- Write→Read→Trigger→Profit closed loop
- Deep Root Cause analysis section (trust boundary chain + individual audits + deepest conclusion)
- Reverse Engineering and Unified PoC section (attack contract set + reverse engineering notes + minimal PoC)
- RPC Replay at Attack Block section (replay anchor + verdict `reproduced`/`partially_reproduced`/`blocked` + exact `forge test` command + on-fork deterministic values)
- Risk Upper Bound (at tx prestate) section (on-fork measurements + `maxDrainableCap = min(balance, accumulatorRemaining)` + `drainedInThisTx` + `residualAfterThisTx` + binding constraint + repro pointer)
- Confidence rating (low/medium/high) computed as `min(rootCauseConfidence, replayConfidence)`

---

## Core Principles

1. **Write-first** — First find "who modified the ledger" (SSTORE), then explain "what others observed." The causal chain is always Write → Read → Trigger → Profit
2. **Competing hypotheses** — Maintain 2-4 mutually exclusive explanations per anomaly; falsify the lowest-cost one first
3. **Adversarial thinking** — Malicious tokens/contracts will deceive you. `balanceOf`, events, and return values can all be forged. Trust the SSTORE chain
4. **Distinguish setup from cashout** — The final swap/withdraw hop is rarely the root cause; the real bug lies in the setup/accumulate/flush path
5. **Accumulator buckets are first-class citizens** — `pending fee/reward/debt/burn/distributor credit` are often exploited as attacker-controllable intermediate reservoirs
6. **No evidence-free negation** — "X did not happen" must include search scope and pattern
7. **Trust boundary penetration** — Audit every validation function on the attack path; "application layer is already closed" is not a reason to stop
8. **Evidence stratification** — State writes > reproducible values > events > source code > intuition; critical conclusions must rest on high-tier evidence

## Additional Resources

- For the complete 6-phase workflow, LLM strategies, and bytecode forensics playbook, see [docs/ATTACK_TX_ANALYSIS_METHODOLOGY.md](docs/ATTACK_TX_ANALYSIS_METHODOLOGY.md)
- For mandatory gates, evidence thresholds, and stop conditions (highest priority), see [docs/ATTACK_TX_ANALYSIS_SPEC.md](docs/ATTACK_TX_ANALYSIS_SPEC.md)
- For modular checklists triggered by specific attack patterns, see [docs/ATTACK_TX_ANALYSIS_MODULES.md](docs/ATTACK_TX_ANALYSIS_MODULES.md)
- For deep root cause drilling after Phase 6, see [docs/ATTACK_TX_ANALYSIS_DEEP_DIVE.md](docs/ATTACK_TX_ANALYSIS_DEEP_DIVE.md)
- For the mandatory post-deep-dive attacker-contract reverse engineering, PoC generation, and RPC replay stage, see [docs/ATTACK_TX_ANALYSIS_POC_REPLAY.md](docs/ATTACK_TX_ANALYSIS_POC_REPLAY.md)
- For the concrete Foundry + anvil tx-prestate fork harness (repo layout, `.t.sol` matrix, deterministic assertions), see [docs/ATTACK_TX_ANALYSIS_FORK_HARNESS.md](docs/ATTACK_TX_ANALYSIS_FORK_HARNESS.md)
- For the defensive read-only risk upper bound evaluation, see [docs/ATTACK_TX_ANALYSIS_RISK_BOUND.md](docs/ATTACK_TX_ANALYSIS_RISK_BOUND.md)
- For a reference end-to-end case study, see [case_studies/tx-0x767d8a0f-lista-flap/README.md](case_studies/tx-0x767d8a0f-lista-flap/README.md)

## External Dependencies

| Tool | Purpose | Authentication |
|------|---------|---------------|
| Alchemy RPC | trace_transaction, debug_traceTransaction, eth_getCode | API key in config.json rpc_url |
| Etherscan/BscScan | Contract source code, ABI, verification status | config.json etherscan_api_key |
| openchain.xyz | selector → function signature lookup | No authentication required |
| [Heimdall-rs](https://github.com/Jon-Becker/heimdall-rs/) | EVM bytecode decompilation | Local binary ~/.bifrost/bin/heimdall |
| OpenAI API | LLM-optimized decompiled code (optional) | OPENAI_API_KEY + OPENAI_API_BASE env vars |
| [Foundry `forge`](https://book.getfoundry.sh/) | Compile + run `.t.sol` replay and risk-bound tests | None; binary on $PATH |
| [Foundry `anvil`](https://book.getfoundry.sh/anvil/) | Local tx-prestate fork via `--fork-transaction-hash` | Upstream RPC URL in `$BSC_RPC_URL` (or equivalent) |
| [Foundry `cast`](https://book.getfoundry.sh/cast/) | On-fork sanity probes (`chain-id`, `block-number`, `tx`, `storage`) | Same RPC URL as anvil |
