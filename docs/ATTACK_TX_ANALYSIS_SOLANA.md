## Solana Transaction Analysis Methodology

> This document defines the **default analysis path for Solana transactions** in this repository.  
> When `--network solana` is used, this document supersedes the EVM-only methodology / SPEC / replay stack unless the user explicitly asks for a deeper custom experiment.

---

## Objective and Scope

This methodology is designed for **systematic analysis of Solana transactions**, including:

- suspicious or exploit transactions involving custom programs
- SPL token / Token-2022 balance movements
- authority misuse, account substitution, PDA misuse, or signer privilege abuse
- routine but confusing transactions such as vote, stake, or maintenance operations

The goal is to produce an analysis that is:

- **evidence-driven**: anchored to transaction metadata, instructions, account roles, and account state
- **Solana-native**: no hallucinated EVM concepts like `SSTORE`, selector maps, or opcode traces
- **LLM-friendly**: compress large account/instruction payloads into a clear causal narrative

---

## Solana Evidence Reality

Standard Solana RPC can usually provide:

- `getTransaction` payloads in `json`, `jsonParsed`, and `base64`
- outer and inner instructions
- program invocation order
- logs
- lamport balance diffs
- token balance diffs
- touched-account snapshots via `getMultipleAccounts`
- program account / ProgramData metadata for invoked programs

Standard Solana RPC does **not** generally provide:

- an EVM-style `debug_traceTransaction`
- opcode-by-opcode execution traces
- universal verified source-code retrieval
- a universal local fork + replay flow equivalent to `anvil --fork-transaction-hash`

When source-level understanding is required for a custom Solana program:

- first use local artifacts in `contract_sources/` to identify the program account, ProgramData, binary metadata, upgrade authority, and any naming hints
- then look for the implementation in the project's public repository, the protocol's GitHub organization, Anchor workspace, or auditor-linked source repository
- if the exact deployed binary cannot be matched to a public repo commit, explicitly downgrade confidence and mark source attribution as `blocked` or `partial`

Therefore, all conclusions must be phrased in terms of **instructions, account privileges, state transitions, authority relationships, and value movement**.

---

## Core Principles

### 1. Instruction-first, not log-first

Logs help localize execution, but the primary unit of analysis is:

`instruction -> accounts passed in -> signer/writable privileges -> account/program state effect`

Do not treat logs as root-cause evidence by themselves.

### 2. Classify the transaction before calling it suspicious

Before searching for an exploit, classify the transaction into one of these buckets:

- **consensus / maintenance**: vote, stake, nonce, rent, system upkeep
- **simple asset movement**: SOL transfer, SPL transfer, close account, approve/revoke
- **normal application interaction**: swap, stake, claim, mint, governance action
- **exploit candidate / suspicious state transition**

If the transaction is routine, the analysis should say so clearly instead of forcing an exploit narrative.

### 3. Account-role discipline is mandatory

For every important instruction, identify:

- who signed
- which accounts were writable
- which accounts were read-only
- which accounts were executable programs
- which accounts were user-owned vs program-owned
- which account acted as authority, mint authority, freeze authority, delegate, vault, PDA, oracle, or config

On Solana, many root causes reduce to **"the wrong account was trusted / writable / accepted as authority."**

### 4. Close the balance-and-state loop

For any economic claim, reconcile all three when available:

- lamport diffs
- token balance diffs
- meaningful account data changes from parsed account snapshots

If assets supposedly moved but no supporting balance/state anchor exists, downgrade the claim.

### 5. Track CPI trust boundaries

When custom programs invoke other programs, the key question is not just "which program ran" but:

- which accounts were forwarded into CPI
- whether signer/writable privilege propagation was expected
- whether downstream programs accepted attacker-controlled accounts as valid

### 6. Maintain competing hypotheses

For every anomaly, keep at least 2 plausible explanations and eliminate them with the cheapest hard evidence first.

Common Solana hypothesis classes:

- **authority misuse**: wrong signer / delegate / authority accepted
- **account substitution**: attacker-supplied account passed where a canonical PDA / vault / oracle / mint / config was expected
- **owner-check failure**: program failed to verify account owner / discriminator / mint / seeds / bump
- **writable privilege abuse**: attacker gained mutation ability over a sensitive account
- **stale or manipulable external state**: oracle/config/account data was outdated or attacker-controlled
- **routine maintenance**: transaction is benign, only expensive-looking because of raw account metadata

### 7. No evidence-free negation

If you claim "X did not happen", you must state the search scope and anchor, for example:

- searched all outer/inner instructions and found no SPL Token transfer
- lamport diffs only show fee debit on the signer
- no third-party writable value-bearing accounts changed in the touched-account set

Otherwise write only: "X has not yet been located in the current artifacts."

---

## Solana Analysis Workflow

### Phase 1: Triage

Read:

- `trace/summary.json`
- `trace/transaction_jsonParsed.json`
- `trace/instructions/*.json`
- `trace/log_messages.json`
- `trace/lamport_diffs.json`
- `trace/token_balance_diffs.json`

Output:

- transaction type/classification
- success/failure, fee payer, signers, invoked programs
- high-level economic effect
- whether this looks routine, application-level, or exploit-like

### Phase 2: Participant and Privilege Inventory

Build a roster of:

- signers
- writable user accounts
- writable program-owned accounts
- token accounts / mints / vaults
- authorities and delegates
- invoked programs

For each key account, note:

- `pubkey`
- `owner`
- `executable`
- role in the transaction

This phase should answer:

> Which accounts had the power to authorize, mutate, or receive value?

### Phase 3: Instruction / CPI Phase Map

Compress the transaction into 2-6 phases, for example:

- fund
- approve
- swap
- settle
- withdraw

or for benign system flows:

- sign
- invoke vote program
- update vote state

For CPI-heavy transactions, explicitly identify:

- outer instruction entry point
- inner instruction groups
- which program performed the economically important action

### Phase 4: Value and State Diffs

Analyze:

- signer fee debit
- lamport transfers
- SPL token transfers / mint / burn / close-account effects
- touched-account state changes that matter economically or for control

Important rule:

- If there is **no asset movement beyond fees**, do not write a drain/exploit narrative.
- If there is **authority or configuration mutation without immediate asset flow**, explain it as a control-plane risk, not a realized drain.

### Phase 5: Competing Explanations

For each anomaly, list 2-4 hypotheses and the minimum evidence needed.

Examples:

- abnormal token outflow
  - canonical vault really transferred funds
  - attacker substituted a fake vault / fake mint / fake oracle
  - delegate / authority was legitimately pre-approved
  - transaction was a normal user withdrawal

- suspicious custom-program invocation
  - program accepted attacker-controlled writable account
  - signer check was missing
  - PDA derivation / seed validation was missing
  - transaction only exercised a benign instruction

### Phase 6: Evidence Closure

Close the analysis using this Solana-native chain:

`Instruction -> Privilege / account assumption -> State change -> Downstream acceptance -> Economic or control impact`

Examples:

- `transfer_checked` / CPI moved tokens from canonical vault -> attacker received assets
- custom program accepted attacker-controlled config PDA -> downstream accounting used manipulated parameters
- vote program `towersync` updated validator vote state -> no user-value movement, only normal consensus activity

### Phase 7: Deliverable

Conclude with one of the following clearly labeled outcomes:

- `routine transaction`
- `normal application transaction`
- `suspicious but not proven exploit`
- `confirmed exploit / authority failure / account-substitution issue`

---

## Solana-Specific Mandatory Questions

For every Solana analysis, answer these questions explicitly:

1. **What type of transaction is this?**  
   Consensus / maintenance / transfer / application / exploit candidate

2. **Who paid and who signed?**  
   Distinguish fee payer from authorities and asset recipients.

3. **Which programs were actually invoked?**  
   Include whether only native programs ran, or custom application programs too.

4. **Which writable accounts mattered?**  
   Especially vaults, token accounts, mints, PDAs, config accounts, oracle accounts, vote accounts.

5. **What changed economically or administratively?**  
   Lamports, SPL balances, ownership/authority/configuration, or only vote/stake state.

6. **Who lost value, who gained value, or was no value transferred?**

7. **What exact evidence level supports the conclusion?**  
   Transaction metadata only / parsed account data / balance diffs / reproducible math / code/source unavailable / blocked

---

## Exploit-Focused Checklist

When the transaction appears malicious or abnormal, answer all of the following:

### Victim-first

- which third-party accounts lost value or control
- through which instruction or CPI that happened
- where the value or privilege ended up

### Authority-first

- which authority or signer assumption was relied on
- whether that authority was canonical, delegated, PDA-derived, or attacker-supplied
- what validation should have existed (owner check, seeds check, discriminator check, mint match, authority match, signer check)

### Account-substitution

For every critical account passed into a custom program, ask:

- should this have been a canonical PDA?
- should its `owner` have been checked?
- should its mint / authority / discriminator / data layout have been checked?
- was the account merely user-supplied and trusted?

### Token semantics

If SPL tokens are involved, identify:

- token program used (`Tokenkeg...` vs Token-2022 if visible)
- source token account
- destination token account
- mint
- authority / delegate / multisig relationship

---

## Evidence Hierarchy for Solana

From strongest to weakest:

1. **Instruction + account privilege + balance/state-change alignment**
2. **Reproducible economic math from balances / parsed account fields**
3. **Program/account metadata and parsed account state**
4. **Logs**
5. **Program binary presence or partial source metadata**
6. **Pattern matching / intuition**

Do not overstate confidence when only logs or naming conventions are available.

---

## Output Requirements

Write results into `transactions/<signature>/analysis/result.md`.

Recommended section order:

1. **Classification and Verdict**  
   One sentence: what kind of transaction this is, and whether it is routine / suspicious / exploit.

2. **Participants and Roles**  
   Fee payer, signers, recipient/victim accounts, key writable accounts, invoked programs.

3. **Instruction Narrative / Phase Map**  
   The shortest faithful explanation of what the transaction did.

4. **Economic and State Impact**  
   Lamport diffs, token diffs, account-state effects, or explicit statement that only fees/vote-state changed.

5. **Root Cause or Benign Explanation**  
   Solana-native closure:
   `Instruction -> Privilege / account assumption -> State change -> Impact`

6. **Key Evidence**

7. **Open Questions / Blockers**  
   For example: unverified custom program, missing source from RPC and requiring GitHub/repository lookup, no pre/post decoded state for a binary account, ambiguous PDA derivation.

8. **Confidence**  
   `low`, `medium`, or `high`

If a stage cannot be completed, mark it `blocked` and explain why.

---

## Confidence Guide

- **high**: instruction flow, account roles, and balance/state impact all align to a single explanation
- **medium**: economic or control impact is clear, but one or more critical validations/source-level details remain inferred
- **low**: only surface metadata/log evidence exists, or multiple explanations remain unresolved

---

## Explicit Prohibitions

- Do **not** invent EVM concepts such as `SSTORE`, storage-slot provenance, selector maps, or opcode traces for Solana transactions.
- Do **not** force all Solana analyses into exploit language if the transaction is a routine vote/stake/system action.
- Do **not** treat logs alone as proof of value movement.
- Do **not** claim a drain without matching lamport/token/account-state evidence.
- Do **not** claim "no victim" or "no token movement" without pointing to the inspected artifacts.

---

## Minimal Deliverable Templates

### Routine Transaction

```text
Verdict: routine transaction
Type: validator vote / stake / system maintenance / simple transfer
What happened:
- signer X invoked program Y
- account Z state was updated
- only fee debit (or explicit transfer) occurred

Why this is not an exploit:
- no third-party writable value-bearing account lost assets
- lamport/token diffs show ...
- invoked program set is limited to ...
```

### Exploit Candidate

```text
Verdict: confirmed exploit (or suspicious but not proven exploit)
Type: custom-program authority/account-validation failure

Victims:
- ...

Closure:
- Instruction: ...
- Privilege / assumption: ...
- State change: ...
- Impact: ...

Key evidence:
- ...

Blocked / open:
- ...
```
