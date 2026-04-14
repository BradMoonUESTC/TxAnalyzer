# TxAnalyzer — Attack Transaction Analysis

Pull transaction artifacts → analyze root cause following strict methodology → produce audit-grade reports.

## Environment & Configuration

```bash
source venv/bin/activate
```

- `config.json` stores network configuration (RPC URL + Etherscan API Key); if missing, copy from `config_template.json` and prompt the user to fill in Keys
- Supported networks: `bsc` (default), `eth`, `sepolia`, `polygon_amoy`

### Heimdall (required for decompiling unverified contracts)

The project uses [heimdall-rs](https://github.com/Jon-Becker/heimdall-rs/) (Rust version) for EVM bytecode decompilation. Binary expected at `~/.bifrost/bin/heimdall`.

Install via bifrost:

```bash
curl -L https://bifrost.sh | bash
bifrost --install heimdall
```

Verify:

```bash
~/.bifrost/bin/heimdall --version
```

If heimdall is not installed, `pull_artifacts.py` will still work but unverified contracts will lack decompiled source code.

## Core Commands

```bash
# Pull artifacts
python scripts/pull_artifacts.py --network <NET> --tx <TX_HASH> [--timeout 120] [--skip-opcode] [--reuse-log]

# Clean up artifacts
python scripts/cleanup.py --tx <TX_HASH> [--dry-run]

# Decompile (requires OPENAI_API_KEY + OPENAI_API_BASE)
python scripts/decompile.py

# Batch backfill opcodes
python scripts/backfill_opcodes.py [--ctf ctf] [--timeout 600]
```

### `pull_artifacts.py` Internal Pipeline

1. `trace_transaction` RPC → parse call tree → save `tx_trace_*.json` + `tx_calls_*.csv`
2. Per contract address: fetch source/ABI from Etherscan → export `.sol`; decompile via Heimdall if unverified
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
│   └── result.md               # AI analysis result
├── trace/
│   ├── transaction_info.json
│   ├── <index>_d<depth>_*.json # Split by order + depth
│   └── __files_index__.json
├── contracts/
│   └── <addr>.json
├── contract_sources/
│   └── <addr>/
│       ├── __index__.txt
│       ├── *.sol / *.abi.json        # Verified source code
│       ├── decompiled/               # Decompiled if unverified
│       │   ├── raw.sol
│       │   ├── optimized.sol
│       │   └── abi.json
│       └── selectors_from_trace.json
└── opcode/
    ├── tx_assembly_*.json      # Full structLogs data
    └── tx_assembly_*.asm.txt   # Human-readable opcodes
```

## Python Module Reference

### `txanalyzer/tx_analyzer.py` — `TransactionTraceAnalyzer`

- `get_transaction_trace(tx)` → trace_transaction RPC
- `parse_trace_data(resp)` → structured call tree + address set + anomalies
- `analyze_contracts(addresses)` → fetch source/decompile per address
- `export_transaction_assembly(tx, ...)` → debug_traceTransaction export
- `get_function_signature_from_api(selector)` → openchain.xyz query (cached)
- `heimdall_decompile(addr, bytecode)` → Heimdall CLI decompilation

### `txanalyzer/transaction_processor.py` — `TransactionProcessor`

- `process_contracts()` → split JSON per address + copy source files
- `process_trace()` → split JSON per call + generate index
- `process_report()` → copy summary report

### `txanalyzer/heimdall_api.py`

Heimdall CLI wrapper (`~/.bifrost/bin/heimdall`): `decompile()`, `disassemble()`, `decode()`, `cfg()`

## External Dependencies

| Tool | Purpose | Authentication |
|------|---------|---------------|
| Alchemy RPC | trace_transaction, debug_traceTransaction, eth_getCode | API key in config.json rpc_url |
| Etherscan/BscScan | Contract source code, ABI, verification status | config.json etherscan_api_key |
| openchain.xyz | selector → function signature lookup | No authentication required |
| [Heimdall-rs](https://github.com/Jon-Becker/heimdall-rs/) | EVM bytecode decompilation | Local binary ~/.bifrost/bin/heimdall (install via bifrost) |
| OpenAI API | LLM-optimized decompiled code (optional) | OPENAI_API_KEY + OPENAI_API_BASE env vars |

---

## Analysis Workflow

When a user provides a transaction hash requesting attack analysis, execute strictly in the following order.

### Step 1: Pull Artifacts

```bash
python scripts/pull_artifacts.py --network <NET> --tx <TX>
```

### Step 2: Read Methodology (**must not skip, must not partially read**)

Before analysis, **all 4 documents must be read in full**. SPEC has the highest priority.

| Document | Path | Responsibility | Priority |
|----------|------|----------------|----------|
| **METHODOLOGY** | @docs/ATTACK_TX_ANALYSIS_METHODOLOGY.md | 6-phase workflow + core principles + LLM strategies | Baseline |
| **SPEC** | @docs/ATTACK_TX_ANALYSIS_SPEC.md | Mandatory gates, evidence thresholds, stop conditions | **Highest (overrides on conflict)** |
| **MODULES** | @docs/ATTACK_TX_ANALYSIS_MODULES.md | Modular checklists (mandatory when trigger conditions are met) | On-demand |
| **DEEP DIVE** | @docs/ATTACK_TX_ANALYSIS_DEEP_DIVE.md | Deep root cause drilling | Mandatory after Phase 6 |

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

### Available Resources During Analysis

| Resource | Path | Purpose |
|----------|------|---------|
| Contract source code | `transactions/<tx>/contract_sources/` | Verified source or decompiled code |
| Trace | `transactions/<tx>/trace/` | Call records split by depth/order |
| Opcode | `transactions/<tx>/opcode/` | Instruction-level structLogs |
| Contract info | `transactions/<tx>/contracts/` | Per-address metadata |
| Selector mapping | `transactions/<tx>/contract_sources/<addr>/selectors_from_trace.json` | Function signature lookup |
| Summary report | `transactions/<tx>/tx_report.txt` | Transaction overview |

### Step 4: Output Results

Write to `transactions/<tx>/analysis/result.md`.

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

### Output Requirements

`result.md` must include:
- One-sentence root cause + trigger condition + 3-6 key evidence items + 5-10 step minimal reproduction + fix recommendations
- Write→Read→Trigger→Profit closed loop
- Deep Root Cause analysis section (trust boundary chain + individual audits + deepest conclusion)
- Confidence rating (low/medium/high)

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
