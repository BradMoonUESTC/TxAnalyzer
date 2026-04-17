## Post-Deep-Dive Reverse Engineering, Unified PoC, and RPC Replay

> This document is executed **immediately after** `ATTACK_TX_ANALYSIS_DEEP_DIVE.md`.  
> It converts the analysis conclusion into an **attack-contract-centered exploit reconstruction**.  
> Reverse engineering the attacker contract and generating the PoC are treated as **one task**, not two separate deliverables.

---

## Goal

After the root cause and deepest code defect are identified, the next question is:

> **Can we reconstruct the attack contract's real operating logic and replay the exploit against RPC at the attack block?**

This stage exists to answer that question with evidence.

It must:

- Read **all artifacts** under `transactions/<tx>/`, including `analysis/result.md`
- Focus on the **attacker-controlled contract(s)** on the main attack path
- Re-decompile / refine the attacker contract view if needed
- Generate a **unified PoC** that maps directly to the observed trace
- Attempt **RPC-based replay** anchored to the attack block context

---

## Core Principles

1. **PoC is evidence-backed reconstruction, not generic exploit storytelling**  
   Every PoC step must align with trace anchors, contract code/decompiled code, and the closed loop already established in `result.md`.

2. **Reverse engineering and PoC generation are one workflow**  
   If the attacker contract is unverified, decompilation is not an optional appendix. It is part of reconstructing the exploit logic and extracting the exact callable sequence.

3. **Replay must be pinned to the attack block context**  
   Do not replay against latest state. Use the attack transaction's block as the time anchor, and replay against the transaction's pre-state within that block whenever the tooling allows it.

4. **`result.md` is required input, not a summary to ignore**  
   The PoC and replay must inherit the already-proven Write -> Read -> Trigger -> Profit chain and the Deep Root Cause conclusion.

5. **Prefer minimal faithful reproduction over framework-heavy scaffolding**  
   The goal is to reproduce the exploit mechanics with the shortest auditable sequence, not to build a large testing harness unless it materially improves reproducibility.

---

## Mandatory Inputs

Before starting this stage, read the following from `transactions/<tx>/`:

- `analysis/result.md`
- `trace/transaction_info.json`
- `trace/__files_index__.json`
- Relevant trace slices under `trace/`
- `contracts/*.json`
- Relevant attacker/protocol directories under `contract_sources/`
- Relevant bytecode traces under `opcode/` when source/decompiled output is insufficient
- `tx_report.txt`
- `README.md`

If any of the above is missing, state the gap explicitly and continue with the best available evidence.

---

## Strict Execution Flow

### Step 1: Lock the Attack Contract Set

Identify:

- `attacker_eoa`
- `attacker_contracts`
- `primary_attack_contract`
- `supporting_contracts` (routers, helpers, flashloan adapters, malicious tokens, etc.)

Minimum requirement:

- At least one trace-backed reason for why each selected contract belongs to the attack path
- Clear distinction between the attack contract and ordinary third-party infrastructure

### Step 2: Reverse Engineer the Attack Contract for PoC Purposes

For the `primary_attack_contract` and any helper contract required for replay:

- Use verified source code if available
- Otherwise use `contract_sources/<addr>/decompiled/optimized.sol`
- If the existing decompilation is missing critical logic, re-decompile from saved bytecode or live RPC code for that address

You must extract:

- Entry functions used in the attack
- Callee sequence and ordering constraints
- Key parameters and branch selectors
- Required approvals, balances, callbacks, and receiver addresses
- Any hardcoded addresses / constants / selectors that materially affect the exploit

This step is complete only when the contract logic is sufficiently recovered to write a minimal PoC call sequence.

### Step 3: Generate the Unified PoC

Produce a PoC that is directly grounded in the observed attack path.

The PoC must describe:

- Preconditions
- Call sequence
- Per-step purpose
- Critical parameters and addresses
- Expected state transition or observable output at each step
- Profit landing path

Treat the following as the same deliverable:

- "attacker contract reverse engineering"
- "PoC generation"

In other words: do not output a decompilation section that is disconnected from the PoC.

### Step 4: Prepare Attack-Block RPC Replay

Replay must use the attack transaction's block metadata as the anchor.

Required fields:

- `attack_block_number`
- `attack_tx_index` (if available)
- `attack_tx_hash`
- `replay_state_anchor`

Recommended replay anchor:

- Prefer the **pre-state of the attack transaction within the same block**
- If your tooling cannot replay from intra-block pre-state directly, use the closest available approximation and state it explicitly:
  - parent block state + attack block environment
  - same block RPC simulation endpoint with trace/debug support

### Step 5: Execute RPC-Based Replay

Acceptable replay approaches include:

- RPC-backed local fork pinned to the attack block context
- `debug_traceCall`, `trace_call`, or equivalent simulation APIs at the relevant block
- Contract-level call replay with explicit state/time anchoring

The replay must validate as many of the following as possible:

- The attack contract call sequence is executable
- The critical anomaly can be recreated
- The protocol takes the same misjudging or settlement action
- The profit path or key intermediate state matches the real transaction

### Step 6: Render the Replay Verdict

Replay verdict must be one of:

- `reproduced`
- `partially_reproduced`
- `blocked`

If not fully reproduced, explain the narrowest blocker:

- missing dependency
- unavailable RPC feature
- intra-block pre-state not accessible
- bytecode/source gap
- environment mismatch
- unresolved parameter

Do not silently skip replay.

---

## Output Format

Append the following after the Deep Root Cause section in `transactions/<tx>/analysis/result.md`:

```text
## Reverse Engineering and Unified PoC

### Attack Contract Set
(attacker_eoa / attacker_contracts / primary_attack_contract / supporting_contracts)

### Reverse Engineering Notes
(entry functions, key branches, hardcoded addresses, required approvals/balances)

### Minimal PoC
(preconditions + ordered call sequence + why each step matters)

## RPC Replay at Attack Block

### Replay Anchor
(attack_block_number / attack_tx_hash / replay_state_anchor / replay method)

### Replay Result
(reproduced | partially_reproduced | blocked)

### Replay Evidence
(what matched the real attack, what diverged, and why)
```

---

## Prohibitions

1. **Do not generate a generic PoC that is not trace-aligned.**
2. **Do not replay on the latest block and present it as attack reproduction.**
3. **Do not ignore `result.md`; this stage must inherit the prior causal chain.**
4. **Do not treat attacker-contract decompilation as optional when verified source is unavailable.**
5. **Do not mark replay as successful without naming what was actually reproduced.**

---

## Mandatory Follow-Up Documents

This document defines **what** the PoC / replay stage must contain.
The following two documents define **how** to execute it and must also
be read and followed whenever this stage is triggered:

- [`ATTACK_TX_ANALYSIS_FORK_HARNESS.md`](ATTACK_TX_ANALYSIS_FORK_HARNESS.md)
  — concrete Foundry + anvil harness: repo layout, `foundry.toml`, local
  `anvil --fork-transaction-hash` workaround for backends that reject
  `vm.createSelectFork(txHash)`, the required `.t.sol` test matrix
  (blocker-documenting tests, seeded simulation, exact-prestate replay),
  and the deterministic-assertion pattern.
- [`ATTACK_TX_ANALYSIS_RISK_BOUND.md`](ATTACK_TX_ANALYSIS_RISK_BOUND.md)
  — defensive, read-only risk upper bound evaluation: how to compute
  `maxDrainableCap = min(objectBalance, accumulatorRemaining)` from the
  same prestate fork, the required `testRiskUpperBoundAtTxPrestate`
  assertions, and the `result.md` section to append.

A replay that does not follow the fork harness layout, or that omits the
risk upper bound evaluation, is incomplete and must be rendered as
`partially_reproduced` (at best).

## Case Studies

- [`case_studies/tx-0x767d8a0f-lista-flap/README.md`](../case_studies/tx-0x767d8a0f-lista-flap/README.md)
  — reference end-to-end walkthrough of PoC reverse-engineering, exact
  prestate fork replay, deterministic assertions, and risk upper bound
  evaluation for BSC tx `0x767d…f312`.
