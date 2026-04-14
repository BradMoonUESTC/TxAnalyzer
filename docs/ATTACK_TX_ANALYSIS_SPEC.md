## Attack Transaction Analysis Mandatory Specification (SPEC)

> This document is the "inviolable" analysis specification, designed to constrain the analysis process from going off track.  
> The main methodology document provides the workflow and toolbox; **this SPEC provides gates, evidence thresholds, and stopping conditions**.  
> In case of conflict with the methodology document, this SPEC takes precedence.

---

## 1) Evidence Hierarchy (Mandatory)

Conclusion evidence strength from highest to lowest:

- **State Write Evidence (Write/SSTORE level)**: Who wrote what, where, to whom / which key / slot, and under what conditions.
- **Reproducible Numeric Evidence**: Invariants / share formulas / liquidation thresholds and other mathematically verifiable closed-form relationships.
- **Event/Log Evidence**: Can only be used for locating and cross-validation; cannot independently determine root cause.
- **Source/Decompiled Evidence**: Used to explain mechanisms, but must ultimately be confirmed by harder evidence.
- **Pattern Matching/Intuition**: Can only be used for proposing hypotheses; cannot be used for final determination.

---

## 2) Write-object-first Gate (Mandatory Gate)

### 2.1 When the Gate Must Be Triggered

Whenever an anomaly involves a "settlement object's" critical reading or critical settlement, this gate must be triggered (any single hit suffices):

- Pair/Vault/lending position/Oracle etc. shows **extreme settlement readings** (e.g., reserve / share price / health factor / price suddenly becomes a very small constant or jumps abruptly).
- Post-settlement shows **drain / output approaching reserve/totalAssets** phenomena.
- Trace shows `transfer(to=settlement_object)` returning success, but immediately after, the settlement reading still looks like "not received / only received dust".

### 2.2 The Single Question the Gate Must Answer

> Did this transfer that "should have been credited to the settlement object" ultimately get recorded on whose ledger?

### 2.3 Permitted Conclusions (Binary Choice Only)

- **Conclusion A: Indeed credited to the settlement object**  
  - Minimum evidence requirement: Can prove that the write object for "add balance / add assets / add shares" is `to=settlement_object` (or its semantically equivalent key/slot).
- **Conclusion B: Not credited to the settlement object (overwritten / redirected / written elsewhere)**  
  - Minimum evidence requirement: Can prove that the write objects for "debit" and "credit" are inconsistent (e.g., credited to a hardcoded address / different key / conditional branch).

### 2.4 Prohibited Actions (While Gate Is Not Passed)

- Prohibited: Classifying root cause as a **Read-type masquerade**.
- Prohibited: Using **events / receipts / `balanceOf`** to directly substitute for "write object" evidence to pass the gate.

---

## 2.5 Victim-first Gate (Liquidation / Third-party Value Extraction Gate, Mandatory)

### 2.5.1 When the Gate Must Be Triggered

Whenever any of the following signals appear within a transaction, this gate must be triggered (any single hit suffices):

- Liquidation / forced closure related calls to **non-attacker addresses** appear (function name may be unknown, but identifiable through semantics / events / parameters: e.g., `liquidate(user)`, `liquidate_extended`, batch liquidator, `users_to_liquidate` returning multiple addresses).
- **Large-scale third-party position state changes** within the same tx (e.g., batch iteration over users, calling the same "settlement / liquidation / exchange" path for multiple users).

### 2.5.2 The Single Question the Gate Must Answer

> **From which third-party addresses was value extracted? Through what protocol action (liquidation / passive rebalancing / penalty) did it flow to the attacker?**

### 2.5.3 Minimum Deliverables for the Gate (LLM-friendly)

Must output the following fields (partially unknown is acceptable, but none can be empty):

- `victims`: List at least 3 (or all) sample victim addresses
- `extraction_action`: "liquidation / forced rebalancing / penalty / collateral seizure / other"
- `value_path`: Shortest path description from victim assets (collateral or position value) → intermediate contracts (controller/amm/liquidator) → attacker

### 2.5.4 Prohibited Actions (While Gate Is Not Passed)

- Prohibited: Writing root cause's Trigger/Profit as "attacker successfully borrows/lends" without explaining why third parties became extractable.
- Prohibited: Narrativizing "financing steps (flashloan/borrow/mint)" as the primary profit mechanism when third-party value extraction evidence exists.

---

## 3) Competing Explanations and Falsification Order (Mandatory Order)

Any "anomalous phenomenon" must retain at least 2 mutually exclusive explanations, and be falsified in the following order:

- **Write first (where was it written)**: First verify whether the write object is correct (whether it was written to the intended object).
- **Then Read (what was read)**: Then verify whether the reading has caller/condition dependency, or whether it can be spoofed.

> If you observe "readings fluctuating wildly," the first instinct should still be: **Was the write object overwritten/redirected?**

---

## 4) Root Cause Confidence Gate (Mandatory Threshold)

- **high**: Must include at least 1 "write object" level evidence (who wrote, to whom / which key / slot, written value / conditions), and must explain the critical anomaly.
- **medium**: Critical write point has been located, but write object/conditions are not fully determined; or can only close the loop under limited assumptions.
- **low**: Without passing the Write-object-first Gate, any Read-type explanation can only be low, and must clearly state the "shortest falsification action" for each hypothesis.

> **Additional threshold (when root cause involves business logic chain exploitation / multi-step composition)**:  
> To elevate to `high`, in addition to write evidence, the following must also be identified:
> - At least **2** attacker-reachable mechanisms
> - At least **1** shared state bucket or shared settlement object
> - Clear distinction between `flush_or_settlement_action` and `extraction_action`

---

## 5) Mandatory Output Constraints (Preventing Narrativization)

### 5.1 Must State the "Core Contradiction"

Compress the massive trace into a single conflict in one sentence, template:

- `A certain write/transfer action shows success` **but** `the immediately following settlement read/update shows no corresponding change`

### 5.2 Must Write Write→Read→Trigger→Profit Closed Loop

Root cause must be explainable by a single chain:

- **Write**: Write point + write object + conditions
- **Read**: What the critical settlement read returned
- **Trigger**: What settlement the protocol performed based on that reading
- **Profit**: How assets flowed back to form net profit

### 5.2.1 Trigger/Profit Main Line Selection Rule (Mandatory)

When both "financing steps" (flashloan/borrow/mint) and "value extraction steps" (liquidation / collateral seizure / forced rebalancing causing third-party losses) appear within the same transaction:

- **Trigger** must prioritize the action that "directly causes third-party losses and transfers value to the attacker" (typically liquidation / seizure / settlement), not the financing action.
- If you insist on writing Trigger as lending disbursement / self-borrowing-repayment, the evidence must explicitly prove: **no third-party victim value was extracted**, or the extraction is not the primary source of profit.

### 5.2.2 Negative Claim Constraint (Mandatory, Preventing "absence of observation equals absence")

If you write negative claims such as "not observed / did not occur / does not exist," you must simultaneously output:
- `negative_claim`: The action/phenomenon you are negating (e.g., "no exchange occurred")
- `search_evidence`: The patterns and scope you searched (e.g., "scanned `exchange(` / `swap` in decoded_input across trace" or list the call windows you inspected)

Otherwise, the negative claim is considered a SPEC violation (narrativization / step-skipping).

### 5.3 Recommended: Split "Write Evidence" into 1a/1b (Adversarial Token/AMM Scenarios)

- **Evidence 1a (Debit write object)**: How the sender's balance / critical state was debited (written to whom / which key)
- **Evidence 1b (Credit write object)**: How the receiver's balance / critical state was credited (written to whom / which key)

If the objects in 1a and 1b are inconsistent, this typically directly constitutes the root cause.

### 5.3.1 Setup Chain vs. Extraction Chain (Mandatory When the Same Contract Is Hit Multiple Times or Accumulation Buckets / Maintenance Functions Exist)

When the same contract/system is called multiple times within the same tx, and these calls collectively modify the same state bucket or settlement object, the following must additionally be output:

- `phase_map`: Tag at least the hit phases from `finance/setup/accumulate/flush/extract/repay`
- `shared_state_bucket`: e.g., `pending fee/reward/burn/debt/distributor credit`
- `shared_settlement_object`: e.g., Pair/Vault/Router/Distributor/Dead address/Oracle input
- `setup_or_accumulation_actions`: Which actions are "priming" for the subsequent anomalous state
- `flush_or_settlement_action`: Which action actually commits the accumulated state to the ledger / reserves / price input / burn address
- `extraction_action`: Which action converts the anomalous state into profit (swap/redeem/withdraw/liquidate)
- `why_composable_in_one_tx`: Explain in 1-2 sentences "why the attacker can atomically chain these steps together"

### 5.3.2 Special Receiver / Path Branch Evidence (Mandatory When Narrative Involves `to/receiver/path/...` Branch Selection)

If your conclusion contains expressions like:
- "Setting `receiver` to a certain address triggers special logic"
- "Special branch taken for `router/pair/dead/distributor`"
- "A certain path / target address hits different transfer / burn / reward logic"

You must output:
- `branch_condition`: The condition triggering the branch (e.g., `to == router`, `receiver == router`, `path[i] == tokenX`)
- `actual_input_value`: The actual value passed in this tx
- `branch_effect`: What object/state the branch specifically modifies (balance, reserves, accumulation bucket, burn transfer, distribution object, etc.)

### 5.3.3 Prohibited Actions (When the Above Scenarios Are Not Fully Documented)

- Prohibited: Writing only the last hop `swap/redeem/withdraw/liquidate` as root cause without explaining how the anomalous state was created by preceding steps.
- Prohibited: Uniformly downgrading steps that modify `shared_state_bucket` or `shared_settlement_object` to "merely preparatory actions."
- Prohibited: Writing "special receiver / path branch" as a deterministic conclusion without `branch_condition + actual_input_value + branch_effect`.

---

## 5.4 Oracle / Health Factor Input Decomposition (Mandatory When Liquidation / Health Factor Is Involved)

Whenever the attack path involves health factor / liquidation determination, the following must be output:

- `oracle_used_by`: Which contract reads which oracle / price function when determining health factor / liquidation
- `oracle_components`: What controllable components make up the price (e.g., pool price, vault redemption rate, aggregator, discount factor)
- `which_component_changed`: Which specific component changed within the tx (must be pinpointed via "return value alignment")

> Purpose: Avoid "seeing a price jump and telling a story"; instead, attribute the jump to a controllable input (swap? ERC4626 rate? donation? redeem?).

---

## 5.5 ERC4626 / Share Token Mandatory Check (When Collateral / Oracle Involves Shares)

Must execute this check when any condition is hit:

- Collateral or oracle input uses `convertToAssets/convertToShares`, share price, `totalAssets/totalSupply`
- Or share pricing is observed to jump within the same tx

Must answer at least three questions (general and actionable):

1) **Did `totalAssets` change, did `totalSupply` change, or did both change?**  
2) **What is the write entry point for the change?** (donation / third-party accounting / `deposit|mint|withdraw|redeem` / stake, etc.)  
3) **How does this change enter the oracle / health factor determination?** (Which read consumed it)

Additionally:
- If you claim that a "supply knob (redeem/mint/deposit/withdraw)" participated in the manipulation, you must execute Module F (Supply Knob Evidence), providing `totalSupply_before_after` and `supply_ops`; otherwise, a supply knob must not be written as a definitive link in the causal chain.

---

## 5.6 Batch Liquidation Causal Closure (Mandatory When Victim-first Gate Is Triggered)

When batch liquidation / large-scale simultaneous third-party degradation occurs, an additional "Victim Degradation Chain" must be output, which must include the following fields:

- `push_action`: At least one controllable push action (typically a large swap/exchange), with trace anchor
- `migration_or_mechanism`: If the protocol has banded AMM/LLAMMA/passive rebalancing mechanisms, at least one mechanism trigger anchor must be provided (e.g., internal `exchange` / band-related calls)
- `oracle_component_changed`: Specify which component in the oracle / health factor input actually changed (pool price? ERC4626 rate? other?), with alignment evidence
- `why_many_victims`: Explain in 1-2 sentences why many users are affected simultaneously (e.g., same oracle input / same set of band rebalancing logic)

> If no anchor can be provided for `push_action` and `migration_or_mechanism`, then "batch liquidation" must not be written as a deterministic main-line conclusion (medium at most, and the shortest supplementary evidence action must be listed).

### 5.6.1 push_action External Swap Mandatory Requirement (Highly General)

When outputting `push_action`, the following must be satisfied simultaneously:
- **Must include at least 1 external AMM/DEX swap/exchange anchor** (Curve/Uniswap/Router etc.); cannot only write "protocol-internal exchange" or "liquidation settlement withdraw."
- Must output `top_swaps`: List the Top-3 swaps in this tx sorted by input volume (can use `decoded_input` amount parameter or adjacent ERC20 transfer amounts as proxy), with trace anchor and pool/router address for each.

Additionally, for each swap in `top_swaps`, the following must be output:
- `in_token` / `out_token` (at minimum token addresses; symbols may be appended if resolvable)
- If Curve i/j form, Module E (Pool Coin Resolution) must be executed, mapping `i/j` to specific tokens (otherwise writing token pair conclusions like "alUSD-sDOLA" is not allowed)

> Purpose: Avoid misidentifying internal settlement actions as "price-pushing actions," thereby missing the real driving factor of "large external pool swap changing ratios/prices."

### 5.6.2 mechanism_action Temporal Order Requirement (Highly General)

If you claim the existence of "mechanism migration / passive rebalancing / bands causing user degradation," you must:
- Explicitly annotate `mechanism_action_happens_before_liquidation=true/false`
- If true: The anchor must come from mechanism calls / state reads **before `users_to_liquidate()`** (e.g., `exchange` / band / tick / user share callback / internal rebalancing after price push).
- If false: Must explicitly acknowledge it is a "liquidation settlement action" and cannot use it as the primary evidence for "why users degraded."

Additionally: If you claim the existence of "bands / mechanism causing passive position migration / rebalancing," Module G (Pre-liquidation Migration Evidence) must be executed, providing:
- `pre_liq_mechanism_calls` (pre-liquidation anchors, and withdraw settlements are not allowed)
- `victim_specific_evidence` (at least 1 victim directly referenced by the mechanism call before liquidation)

Otherwise, "passive migration / rebalancing causing degradation" must not be written as a deterministic conclusion.

---

## 5.7 Oracle Output Value Before/After Alignment (Mandatory When Narrative Involves "Price Changed from A to B")

If your conclusion/narrative contains expressions like "price rose from \(A\) to \(B\)" (e.g., `price_w`, `price_oracle`, share price, health factor input), you must output:
- `price_metric`: The specific function/metric name you are referencing (e.g., `oracle.price_w()`)
- `before_anchor` / `after_anchor`: Trace anchors for the two readings (must be within the same tx, and the read value must be locatable)
- `before_value` / `after_value`: The raw values read (preferably preserving 1e18 precision integers or 18-decimal notation)

Otherwise, the "from A to B" numerical narrative must not be used (can only write "a significant jump occurred," and the shortest supplementary evidence action must be provided).

## 6) Mandatory Sentence Patterns (Preventing LLM Step-Skipping)

When you see `transfer(to=settlement_object)` showing success + `sync() / settlement` reading an extremely small balance / extreme value, you must first write:

- `Gate status: Not passed / Passed; Conclusion: A or B`
- `Permitted next step:`  
  - Not passed: Only allowed to continue "ledger-entry object verification"; not allowed to classify root cause as Read-type.  
  - Conclusion B: Proceed directly to "settlement write → trigger → profit" closed loop.  
  - Conclusion A: Only then allowed to focus investigation on Read/Order/Math/Proxy branches.

---

## 7) Stopping Conditions (Cannot Converge Until Satisfied, Cannot Stop Until Satisfied)

The following conditions must all be met before issuing "final root cause (medium/high)" and concluding:

- At least one critical write point has been located and explained, including the **write object** (written to whom / written where)
- All critical anomalous phenomena can be explained by a single causal chain (no "residuals")
- Profit path can be verified via closed-loop calculation (fund flows consistent with key formulas)
- **Trust boundary penetration (mandatory)**: Every validation/verification function on the attack path has been audited (source code opened, boundary conditions checked), with SECURE/VULNERABLE conclusion given. Not allowed to skip source code audit of deeper validation functions (such as proof verification, signature validation, Merkle tree implementation) on the grounds that "Candidate A already closes the loop"

> **Additional stopping condition (mandatory when Victim-first Gate is triggered)**: Must explain "why these third parties became extractable (liquidatable / seizable / passively rebalanced)," and align that reason with controllable actions within the transaction (swap / oracle input / mechanism migration); otherwise, issuing a final root cause (medium/high) is not allowed.

---

## 8) Common Misjudgment Sources (Mandatory Avoidance)

### 8.1 "Pre/Post Transaction Diff" Cannot Substitute for Write Object Evidence

Many analysis tools can only provide **pre/post transaction** `stateDiff/storageDiff/prestate(diffMode)`, which have two fatal blind spots:

- **Blind spot 1 (net-zero changes disappear)**: If a mapping/slot undergoes "add then subtract / subtract then add" within the transaction and returns to its original value, the pre/post diff may not show the write; but this does not mean "no write occurred."
- **Blind spot 2 (cannot answer "written to whom")**: Even if some slot changes are visible, it may not be possible to uniquely determine whether the "debit write object (1a) / credit write object (1b)" is consistent with `to=settlement_object`.

Therefore:

- **Prohibited**: Using "Pair balance change not seen in diff" to pass the Write-object-first Gate.
- **Allowed**: Using diff only for **cross-validation** (e.g., confirming Pair's reserves slot was written, confirming final profit landing point), but gate conclusions must fall back to "write object" level evidence.

### 8.2 Minimum Acceptable Form for Gate Evidence Collection (Choose Any One)

When you suspect "`transfer(to=settlement_object)` was intercepted/overwritten/redirected," any of the following materials can serve as gate evidence sources (ordered from strongest to weakest):

- **Instruction-level write chain**: Directly locate `SSTORE` within the `transfer/transferFrom` path, and decompose into **1a debit object** and **1b credit object** (especially hardcoded `PUSH20` fixed addresses, or mapping keys that are clearly recoverable).
- **Contract-level recoverable write object**: Source code / disassembly clearly shows "the recipient was overwritten to a fixed address / conditional branch address," and can be aligned to the actual transaction call path (e.g., "triggered only in Pair/Router scenarios").

> Note: Event `Transfer` / receipt `return 1` / `balanceOf` output can only be used for locating and verification, and cannot directly substitute for gate evidence (see 2.4).
