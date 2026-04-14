## Modular Appendix (Optional but Recommended)

> Purpose: Extract frequently missed attack mechanisms into standalone modules to avoid overloading the main workflow.  
> Usage: When you hit a trigger condition in a transaction, execute the corresponding module as a "mandatory checklist" and write the results back into the Phase 2/3/5 closure loop.

---

## Module A: Liquidation-driven Extraction

### Trigger Conditions (any match)
- `users_to_liquidate()` returns multiple addresses, or multiple `liquidate(victim, ...)` calls targeting different `victim` addresses appear
- Within the same tx, settlement/seizure/forced position conversion is executed against a large number of third-party addresses

### 3 Questions You Must Answer (LLM-friendly)
1) **Who are the victims?** (at least 3 sample addresses)  
2) **How is value extracted?** (liquidation/seizure/penalty/forced position conversion)  
3) **Why did they all deteriorate simultaneously?** (same controllable input, same mechanism, same time sequence)

### Minimum Evidence Requirements
- The victim set must come from trace parameters/return values (not intuition)
- Provide at least 1 transfer anchor showing "assets written out from position/AMM to liquidator/attacker"

---

## Module B: ERC4626 Share Pricing Manipulation (Assets Knob + Supply Knob)

### Trigger Conditions (any match)
- Oracle/health factor input uses `convertToAssets/convertToShares`
- Share exchange rate spikes within the same tx

### Mandatory Three Questions
1) **Did `totalAssets` change, `totalSupply` change, or both?**  
2) **What is the entry point for the change?** (donation/third-party accounting vs `deposit|mint|withdraw|redeem`)  
3) **How does this change feed into oracle/health factor determination?** (who reads it, what do they read)

### Common Blind Spots (must be explicitly checked)
- Only checking donation (assets knob) but missing `redeem` (supply knob)
- Only observing share exchange rate jump, but failing to anchor the specific read where it feeds into the liquidation determination

---

## Module F: ERC4626 Supply Knob Evidence (redeem/mint/deposit/withdraw)

> Goal: Turn "redeem affects totalSupply" from inference into auditable evidence; keep it generic (applicable to any ERC4626/share token).

### Trigger Conditions (any match)
- You mention in your narrative that `redeem/withdraw/mint/deposit` affects share pricing/liquidation input
- Or you claim "the supply knob (totalSupply change) was used" as part of the attack chain

### Mandatory Output (all must be provided)
- `supply_ops`: List all calls related to share supply within this tx (must include at least the matched items from `redeem/withdraw/mint/deposit`)
  - Each entry includes: `trace_anchor`, `method`, `shares_or_assets_amount` (infer from decoded_input/output or adjacent Transfer when possible)
- `totalSupply_before_after`: Provide at least two read anchors of `totalSupply()` **within the same tx**:
  - `before_anchor` / `before_value`
  - `after_anchor` / `after_value`
  - Explain their temporal relationship to `supply_ops` (read before/after the operation)

### Minimum Acceptable Evidence Sources (strongest to weakest)
1) Direct `totalSupply()` call output (before/after within the same tx)
2) Share `Transfer`/`Burn`/`Mint` (if the contract implementation is standard and alignable)
3) If before/after cannot be obtained (trace missing): must explicitly write "not evidenced", and list it as the shortest supplementary evidence action (the supply knob must not be stated as a definitive root cause)

---

## Module C: Large Swap Push + Mechanism Migration (Banded AMM/LLAMMA type)

### Trigger Conditions (any match)
- Protocol components include banded AMM/LLAMMA/segmented mechanisms (or their functions like `exchange/active_band/user_tick` appear in the trace)
- Batch liquidations occur or a large number of third parties deteriorate simultaneously

### Mandatory Output Fields (for writing into the Degradation Chain)
- `push_action`: Which swap/exchange pushed the price/pool ratio (provide trace anchor)
- `mechanism_action`: Which internal mechanism call triggered migration/position conversion (provide trace anchor)
- `downstream_effect`: How the migration affected health factor/liquidation determination (explanation suffices, full recalculation not required)

### Minimum Evidence Requirements
- List at least 1 external swap/exchange anchor (pool/Router)
- List at least 1 mechanism-internal `exchange` or band-related call anchor (AMM/LLAMMA/Controller)

---

## Module G: Pre-liquidation Passive Migration/Position Conversion Evidence (Position Migration Before Liquidation)

> Goal: Prevent miswriting "liquidation settlement actions (withdraw)" as "pre-liquidation migration actions that caused deterioration."  
> This module applies generally to: banded AMM/LLAMMA, auto-rebalancing collateral, segmented mechanisms, or any system where "positions can be migrated by price movement."

### Trigger Conditions (any match)
- You mention in your conclusion/narrative that "bands/mechanism caused passive position conversion/migration/exposure change"
- Or batch liquidations occur and you need to explain "why they all deteriorated simultaneously"

### Mandatory Output (all must be provided)
- `liquidation_anchor`: Trace anchor of `users_to_liquidate()` or the first `liquidate(victim)` (used as the temporal boundary)
- `pre_liq_mechanism_calls`: At least 2 mechanism-related call anchors that occurred **before liquidation_anchor** (cannot be liquidation-internal settlements like `withdraw(victim,1e18)`):
  - Acceptable candidates include: AMM/mechanism `exchange`, band/tick/position reads (e.g., `read_user_tick_numbers(user)`, `get_sum_xy(user)`, `callback_user_shares(user,...)`, etc.), `active_band`/band boundary advancement functions, etc.
- `victim_specific_evidence`: Pick any 1 address from the victims, find at least 1 mechanism call anchor before liquidation that **directly contains that victim address as a parameter** (proving migration/determination is related to that victim's position, not just a global narrative)
- `migration_effect`: Explain in 1-2 sentences "how migration worsened health factor" (e.g., collateral composition shifted, liquidatable range crossed threshold). Full recalculation not required, but must correspond to the anchors and temporal ordering above

### Prohibitions
- Prohibited: Using only post-liquidation or liquidation-internal `withdraw`/`transferFrom` to prove "pre-liquidation migration occurred."
- Prohibited: Writing "passive band position conversion caused deterioration" as a definitive root cause without `victim_specific_evidence` (maximum medium confidence; must list shortest supplementary evidence action).

---

## Module D: Swap Discovery and Attribution (Generic, Mandatory Top List)

> Goal: Avoid "didn't see it so it doesn't exist," and prevent misidentifying internal settlement actions as swap push actions.

### Trigger Conditions (any match)
- Batch liquidations / large number of third parties deteriorating simultaneously
- Oracle input (pool price / redemption rate / aggregator) spike observed

### Mandatory Output
- `top_swaps` (Top-3, sorted by input amount, each entry must include):
  - `trace_anchor`: Corresponding trace file/index
  - `callee`: Pool/Router address
  - `method`: Swap/exchange function name (from decoded_input)
  - `amount_in` / `amount_out`: Infer from decoded_input or adjacent transfers when possible
  - `path_or_ij`: Uniswap path or Curve i/j (if available)
- `swap_to_oracle_link`: 1-2 sentences explaining which of these swaps most likely affected the oracle input, and why (temporal ordering + input component alignment).

### Minimum Acceptable Evidence Sources (strongest to weakest)
1) `decoded_input` directly provides amount parameters  
2) Adjacent ERC20 `Transfer` amounts within the call subtree (amount_in/amount_out)  
3) If both are missing: can only write "cannot obtain amount directly from existing trace", and list it as "shortest supplementary evidence action" (must not directly deny the existence of the swap)

---

## Module E: Pool Coin Resolution (Resolve i/j/path to Specific Tokens)

> Goal: Make conclusions like "large swap in the alUSD-sDOLA pool" auditable and reproducible, rather than staying at "some Curve pool i/j."

### Trigger Conditions (any match)
- `top_swaps` contains Curve-style `exchange(i,j,...)` / `exchange_underlying(i,j,...)` / `remove_liquidity_one_coin(coin_index,...)`
- Or the analysis narrative mentions "a pool swap changed the in-pool asset ratio / pushed price"

### Mandatory Output (for each matched swap)
- `pool`: Pool address
- `method`: Specific method name (exchange/exchange_underlying/...)
- `i/j` or `coin_index`
- `in_token` / `out_token`: Must provide token addresses; if the symbol (alUSD/sDOLA/crvUSD…) can be inferred from trace/contract source, append `symbol`
- `evidence`: 1-2 anchors explaining how you resolved it (any one of the following suffices):
  1) **Intra-trace static call**: e.g., `coins(i)` / `underlying_coins(i)` / `N_COINS()` / `get_balances()` call results on the pool within the same tx  
  2) **Adjacent Transfer inference**: Within the swap subtree, observed `tokenX.transferFrom(attacker->pool, amount_in)` and `tokenY.transfer(pool->attacker, amount_out)`  
  3) **Source code/ABI corroboration**: Contract source/ABI indicates coin index meaning + aligned with (1)(2)

### Prohibitions
- Prohibited: Writing only "Curve metapool / StableSwapNG" without resolving the coins (this makes the conclusion unverifiable against a specific description like "alUSD-sDOLA").
- Prohibited: Claiming "this pool is the X-Y pool" without coin resolution evidence; must downgrade to "candidate pool" and list the shortest supplementary evidence action (e.g., search trace for `coins(` / inspect swap subtree transfers).

---

## Module H: Multi-mechanism Business Chain and Accumulation Bucket Flush (Business-logic Composition)

> Goal: Cover scenarios where "each mechanism looks like normal business logic individually, but the attacker chains them together within a single tx to cumulatively affect the same state bucket/settlement object."  
> Common in: deflationary tokens, reward distributors, fee buckets, deferred settlement, public maintenance/flush/sync entry points.

### Trigger Conditions (any match)
- The same contract is **called 3+ times** within a single tx, with different function responsibilities (e.g., `deposit/claim/sell/flush/distribute/sync`)
- `pending/reward/fee/burn/debt/distributor` type **accumulation state / deferred settlement state** appears
- A public `flush/claim/settle/distribute/sync` entry point exists that can immediately apply the accumulated state to Pair/Vault/Oracle/dead address
- The same settlement object (Pair/Vault/Router/Distributor/Dead address) is reached by multiple mechanisms

### Mandatory Five Questions
1) **What is the shared state bucket?**  
   Who increments it, who drains it, who reads it?
2) **What is the shared settlement object?**  
   How does each mechanism act on it (modify balance/modify reserves/modify shares/modify price input)?
3) **Which inputs are responsible for "selecting the branch"?**  
   At minimum, explicitly check `from/to/receiver/path/msg.sender/tx.origin` to see if a special receiver or special path is hit.
4) **Why can these mechanisms be chained within a single tx?**  
   Is it because they are publicly accessible, lack access control, lack cooldown/epoch, or the atomic call ordering is controllable?
5) **What is the final-hop profit action?**  
   Is it "directly creating the vulnerability," or merely converting the anomalous state created by preceding steps into profit?

### Mandatory Output Fields
- `phase_map`: At minimum, label the main path with the matched phases from `finance/setup/accumulate/flush/extract/repay`
- `shared_state_bucket`: e.g., `pending burn` / `reward debt` / `fee bucket` / `distributor credit`
- `mechanisms`: List at least 2 mechanisms, each including:
  - `entry`: Entry function/action
  - `effect_on_bucket_or_object`: Which shared state bucket or settlement object it modifies
  - `trace_anchor`: Corresponding trace anchor
- `branch_selector_inputs`: Inputs that trigger the special branch (e.g., `to=router`, `receiver=router`, `path[i]=tokenX`)
- `flush_or_settlement_action`: Which action actually applies the accumulated state to the settlement object/dead address/reserves/price input
- `extraction_action`: How the anomalous state is ultimately converted into profit (swap/redeem/withdraw/liquidate)
- `why_composable_in_one_tx`: 1-2 sentences explaining "why the attacker could atomically chain these mechanisms"

### Minimum Evidence Requirements
- At least 1 `shared_state_bucket` or `shared_settlement_object` identified
- At least 2 trace anchors from different mechanisms, both aligning to the same bucket/object
- If the narrative involves special receiver/path branching, must provide actual input values, not just "hit the special branch"

### Prohibitions
- Prohibited: Writing only the final-hop `swap/redeem/withdraw` as root cause without explaining how preceding steps created the anomalous state
- Prohibited: Labeling all steps that modify the `shared_state_bucket` or the same settlement object as "just preparatory actions"
- Prohibited: Writing "multi-mechanism chained exploitation" as a high-confidence conclusion without `why_composable_in_one_tx`

---

## Module I: Cross-chain Bridge / Proof Verification / Message Authentication Attack

### Trigger Conditions (any match)
- Cross-chain message handling functions appear in the trace (`handlePostRequests`, `dispatchIncoming`, `onAccept`, `receiveMessage`, `executeMessage`, `verifyAndDeliver`, etc.)
- The attack path involves proof/Merkle verification (`verifyProof`, `calculateRoot`, `processProof`, `MerkleMultiProof`, `MMR`, etc.)
- The attacker triggered privileged actions on the target chain via cross-chain messages — such as permission changes, minting, or asset transfers

### 5 Questions You Must Answer (in order, cannot skip)

1) **How does the message enter the system?** Draw the complete call chain: `attacker → handler → host/dispatcher → application module`, annotate what verification each layer performs

2) **Is the proof verification implementation correct?** (must open full source code for line-by-line review)
   - Check the following boundary conditions line by line:
     - Is `leaf_index >= leafCount` rejected? (if not, the proof path may skip a leaf, allowing arbitrary requests to pass verification)
     - Is `proof.length == 0` or `leaves.length == 0` rejected?
     - Can loops be skipped due to boundary conditions (causing leaves to not participate in root calculation)?
   - Core determination: **After modifying any field of the request, does proof verification definitely fail?** If not necessarily → binding broken → VULNERABLE

3) **Does the message hash/commitment bind all critical fields?**
   - Locate the `message.hash()` / `commitment = keccak256(abi.encode(...))` implementation, confirm whether `from`, `to`, `body`, `nonce` are all included

4) **Is application-layer authentication sufficient?**
   - Does "chain-level authentication" (`source == trustedChain`) exist but lack "sender-level authentication" (`from == trustedModule`)?

5) **Which layer is the true root cause?**
   - Proof verification has a bug → proof verification is the root cause (even if the application layer also has flaws)
   - Proof is correct but application-layer authentication is insufficient → application layer is the root cause
   - Both have independent bugs → both are root causes

### Mandatory Output
- `trust_boundary_chain`: Each layer's verification function + SECURE/VULNERABLE conclusion
- `proof_verification_audit`: Boundary condition check results for the proof function source code
- `deepest_root_cause`: Deepest-layer code defect, pinpointed to filename + line number

### Prohibitions
- **Prohibited: Skipping proof verification review on the grounds that "the attacker can legitimately send messages on the source chain"**
- **Prohibited: Not inspecting proof verification code on the grounds that "candidate A already closes the loop"**
- **Prohibited: Marking proof verification as SECURE without providing specific boundary condition check evidence**
