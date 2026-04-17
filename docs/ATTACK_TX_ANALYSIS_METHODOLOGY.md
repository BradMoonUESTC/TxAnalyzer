## Objective and Scope

This methodology is designed for **systematic analysis of attack transactions (exploit tx)**, covering common attack categories including AMM/DEX, lending/Vault, oracle, permission/signature, reentrancy/callback, proxy/implementation mismatch, non-standard ERC20, tokenomics/deflationary/reward distribution, and more.

The design goal is to be **particularly LLM-friendly**: avoid "manual assembly reading" as much as possible, and instead adopt an **evidence-driven + causal closure + minimal falsification** workflow that enables LLMs to rapidly converge on a unique root cause within massive traces.

---

## Core Principles (The Most Important Abstraction Layer)

- **First find "who modified the ledger," then explain "what others observed"**  
  On-chain systems can be analogized to databases: the hardest causal chain is always  
  **Write (SSTORE/state change) → Read (SLOAD/view return value) → Trigger (protocol logic) → Profit (asset reflow)**.  
  Working backwards from "an anomalous read value" is prone to misjudgment.

- **Maintain a "competing explanation set" and rapidly falsify with minimal checks**  
  When you observe an anomalous phenomenon (price, reserve, balance, shares, etc.), do not immediately construct a narrative. Retain at least 2–4 mutually exclusive explanations, write down the "minimum evidence requirement" for each, and eliminate incorrect branches using the lowest-cost check first.

- **Evidence strength hierarchy: state writes > reproducible numerical values > events > decompiled/source code > intuition**  
  Key conclusions must rest on high-tier evidence (especially "who wrote what state, and where").

- **Assume adversarial by default: assume the opponent will deceive you**  
  Common tactics of malicious tokens/contracts include "deceiving the protocol/deceiving the analyst": caller-dependent `balanceOf`, special-case transfers for Pair/Router, fabricated events, proxy context confusion, etc. The methodology must be resilient against such adversarial behavior.

- **Distinguish "condition-setting actions" from "monetization actions"**  
  In many attacks, the final hop is merely an ordinary `swap/redeem/withdraw/liquidate`; the true root cause is often in an earlier **setup/accumulate/flush/sync** chain.  
  If you can only explain "how the money came out" but cannot explain "how the anomalous state was created within the same transaction," the analysis remains at the surface level.

- **Treat "accumulation buckets / deferred settlement state" as first-class citizens**  
  For states like `pending fee`, `reward debt`, `pending burn`, `distributor credit`, `debt bucket`, `rebalance buffer`, do not dismiss them as "business details."  
  They are often **intermediary pools controllable by the attacker**: first accumulate, then trigger a one-time effect on Pair/Vault/Oracle through public `flush/claim/settle/sync` entry points.

- **Prohibit "unsupported negative statements"**  
  In attack analysis, "X did not happen / X was not observed" is often a source of misjudgment.  
  If you write a negative statement, you must simultaneously provide:  
  - The **explicit search scope and pattern** used for investigation (e.g., "searched the trace for `exchange(` / `swap` / `liquidate`")  
  - Or provide hard evidence for "why it can be ruled out" (e.g., a component's input was sampled twice within the tx and was completely identical).  
  Otherwise, you may only write "X has not yet been located within the examined window (and list the next minimal investigation action)."

- **Penetrate all trust boundaries; do not stop at an intermediate layer (critically important)**  
  An attack typically crosses multiple trust boundaries (proof verification → message dispatcher → application handler → token logic). **"The application-layer explanation already forms a closed loop" is not a reason to stop**—you must ask "How did the attacker reach this layer? Is the validation/verification code at the previous layer correct?"  
  - For every validation/verification function on the attack path (`verifyProof`, `ecrecover`, `require(msg.sender==...)`, `authenticate`, `processProof`, `calculateRoot`, etc.), **you must open its complete source code and review it line by line**  
  - Even if a layer "appears correct," you must check its **boundary conditions** (zero-length input, index out-of-bounds, empty proof, division by zero, `leaf_index >= leafCount`, etc.)  
  - If you stop at a certain layer, ask yourself: **"If only this layer were fixed, could the attacker still forge valid input through a deeper bug to bypass the fix?"** If the answer is "possibly" or "uncertain," you have not found the true root cause

> **Mandatory Specification (must not be violated)**: See `ATTACK_TX_ANALYSIS_SPEC.md` (includes Write-object-first Gate, confidence gates, stop conditions, mandatory sentence patterns).

---

## Six-Phase Workflow (LLM-Friendly)

### Phase 1: Triage

**Input**: Transaction trace (including call_type/from/to/input/output/error), logs/events, token transfers, internal transfers, (if available) state before/after snapshots.

**Output (structured)**:
- **Participant roster**: EOA, attack contracts, victim contracts, key protocol components (pair/router/vault/oracle/proxy).
- **Asset flow overview**: Where main assets originate → key intermediate steps → where final profit lands.
- **Phase labels (strongly recommended)**: Tag main-path calls as `finance/setup/accumulate/flush/extract/repay`, with particular attention to scenarios where **the same contract is called repeatedly** but with different function responsibilities.
- **Business state bucket inventory (strongly recommended)**: List all `pending/reward/fee/burn/debt/distributor` accumulation states appearing in this tx, and annotate "who increments it, who clears it, who reads it."
- **Third-party impact surface**: Whether there are "state changes to non-attacker addresses" (liquidated/repositioned/force-closed/collateral transferred); if so, first list the **set of affected addresses** and the **mechanism of action** (e.g., `liquidate(user)`, batch `users_to_liquidate`, position repositioning triggered by LLAMMA `exchange`).
- **Anomaly indicators**: Which values/behaviors "should not occur" (e.g., reserve sudden change, share spike, instantaneous price explosion, abnormally frequent function calls, reentrancy-pattern call trees, etc.).
- **Profit source classification (strongly recommended)**: Classify profit by "source mechanism" (AMM arbitrage / lending arbitrage / liquidation proceeds / fee reflow / redemption spread / token tax/redirection, etc.), avoiding misidentifying "financing steps (flashloan/borrow)" as "profit mechanisms."

> This phase only performs "anomaly and main-path identification"; no conclusions are drawn.

---

### Phase 2: Draw Two Graphs (Money Flow Graph + Call Graph)

- **Money Flow Graph**: Nodes = addresses/contracts, edges = asset balance changes (transfer in/out/mint/burn/redeem/swap).
- **Call Graph**: Retain only the main call chain related to "anomaly indicators + profit reflow"; collapse everything else into summaries.
- **Phase Map (strongly recommended)**: Further compress the main path into 3–6 phases, e.g., `Finance → Accumulate → Flush/Sync → Monetize → Repay`.  
  This step is especially critical for "multi-mechanism chained exploits / business logic composition root causes."

**What the LLM should do**: Compress the "massive trace" into a **readable main path**.

> **Mandatory supplement (when third-party impact surface exists)**: Draw an additional "Victim Subgraph" that answers only:  
> **"From which third-party addresses did value flow to the attacker?"**  
> This forces the analysis mainline to align with the actual value extraction points such as "liquidation/forced repositioning/position migration," rather than staying on the attacker's self-financing path.

> **Mandatory supplement (when a Victim Subgraph exists)**: Draw an additional "**Degradation Chain**" that answers only:  
> **"Before being liquidated, what controllable actions caused these third parties to go from healthy → extractable?"**  
> The output must include three segments (may coexist):  
> - **Price/oracle input change** (oracle component changed)  
> - **Passive position migration/automatic repositioning** (e.g., banded AMM/LLAMMA mechanism)  
> - **Fee/interest/threshold boundary** (close factor, penalty, rounding)  
> Purpose: Avoid only observing "liquidation occurred" without explaining "why it happened to so many users simultaneously."

> **General constraint (very important)**: The "driving actions" of the Degradation Chain must preferentially come from **external AMM/DEX swaps** (Curve/Uniswap/Router, etc.), not merely "protocol internal settlement actions" (e.g., `withdraw` inside liquidation).  
> You may include "internal exchange/mechanism actions" as a second segment, but you cannot use them to replace the work of identifying "external price driving/pool ratio changes."

---

### Phase 3: Establish a "Competing Explanation Set" for Each Anomaly

For each anomalous phenomenon (e.g., reserve=502, abnormal share change, oracle price deviation), provide at least 2–4 explanations from the following types, noting the "minimum evidence requirement":

- **State was modified (Write type)**: A critical state write (balance/reserve/share/price/permission bit) caused subsequent reads to return anomalous values.
  - Minimum evidence: Locate the relevant `SSTORE`/state update point, confirm the write object and conditions.
- **Read was deceived (Read type)**: The view/return value depends on caller/conditions (e.g., `CALLER`/`EXTCODEHASH` branching) and returns a "fake value."
  - Minimum evidence: The same input returns different outputs under different callers; or clearly visible branch conditions in bytecode/source code.
- **Constraint was bypassed (Constraint type)**: Permission/signature/nonce/validation is missing or replayed.
  - Minimum evidence: A critical require/check is missing or bypassable; signature domain/nonce handling errors.
- **Ordering was violated (Order type)**: Reentrancy/callback causes "external call before state update," or cross-contract ordering errors.
  - Minimum evidence: External call occurs before state update; callback entry exists without a guard.
- **External dependency was manipulated (Dependency type)**: Oracle/TWAP/price source can be instantaneously manipulated; or cross-pool arbitrage.
  - Minimum evidence: Price source is spot/short-window TWAP; attack transaction contains manipulable swap/sync operations.
- **Business logic chained exploitation (Composition type, common and frequent)**: Multiple mechanisms that individually appear to be "normal business" can be chained within the same tx to cumulatively affect **the same state bucket or the same settlement object**.
  - Minimum evidence: List at least 2 mechanisms reachable by the attacker (e.g., `deposit/claim/sell/flush/distribute/sync`), and explain how they collectively modify the same `pending/reward/fee/burn/debt` state or the same Pair/Vault/Oracle reading.
- **Parameter branch selection / special receiver (Branch-select type)**: The same function follows special logic based on different `from/to/receiver/path/msg.sender/tx.origin`.
  - Minimum evidence: Locate the branch condition or fixed address comparison, and align it with the actual tx input parameters (e.g., `receiver=router`, `to=pair`, `path[i]=tokenX`).
- **Position mechanism was driven (Mechanism type, commonly overlooked)**: Some protocols' positions undergo **passive migration/automatic repositioning/segmented (bands) rebalancing** when price/pool state changes (e.g., LLAMMA bands), causing third-party health/collateral composition to change and trigger liquidation.
  - Minimum evidence: Within the same tx (or adjacent steps) there is a large swap/price-driving action that can "significantly push price/pool ratio"; and within the protocol there are calls related to "segmentation/repositioning/exchange" (e.g., `exchange`/band-related reads/writes), followed by `liquidate`/batch liquidation of third-party positions.
- **Precision/rounding/unit error (Math type)**: Decimal, share-to-asset conversion, rounding, overflow/underflow, or custom safe math errors.
  - Minimum evidence: Formula is reproducible and produces attacker advantage; boundary conditions trigger anomalous branches.
- **Proxy/implementation mismatch (Proxy type)**: proxy/implementation, delegatecall context causes different interpretation of storage slots.
  - Minimum evidence: delegatecall path is clear; the same storage slot is read/written under different contract semantics.

---
> **Mandatory Gate (Phase 3.5)**: The "settlement object credit verification (Write-object-first Gate)" has been moved to `ATTACK_TX_ANALYSIS_SPEC.md`.

### Phase 3.6 (New Addition, Strongly Recommended): Gate Evidence Collection Playbook (Making 1a/1b Actionable)

> This section does not change the SPEC gate definitions; it only provides "how to obtain gate evidence" through tool-based steps, specifically covering **adversarial token + AMM** scenarios like this case: `transfer(to=Pair)` returns success, but `sync()/getReserves()` reads dust (e.g., 502).

#### 3.6.1 First Write the "Core Contradiction" and Lock Down 3 Anchor Points

- **Anchor A (Write anchor)**: The hop where `transfer/transferFrom(to=settlement object)` occurs (return value/revert status is only used for localization).
- **Anchor B (Read anchor)**: The critical value read by the settlement object during `sync()/settlement` (e.g., `balanceOf(pair)=502` or `getReserves()`).
- **Anchor C (Profit anchor)**: The final profit landing point (last large transfer out to attacker/EOA).

#### 3.6.2 Competing Explanation Set (Mandatory) and Falsification Order (Fixed: Write Before Read)

- **Hypothesis W (Write-type redirection/ledger modification)**: Debit occurs, but credit is written to a "non-settlement object" (fixed address/conditional address/different key).
- **Hypothesis R (Read-type deception)**: `balanceOf/getReserves` has caller/condition dependency and returns a fake value.

The falsification order is always:

- **First perform 1a/1b (write object verification)**: Only answer "who was credited."
- **Then perform Read deception verification**: Only when the Gate conclusion is A (actually credited) should Read-type be treated as the primary suspect.

#### 3.6.3 Minimum Evidence Collection: Decomposing `transfer` into 1a/1b (The "Conclusive Evidence Template" for Adversarial Tokens)

When a token is unverified/decompilation is incomplete, you are not required to understand all the logic; as long as you capture the following three "strong signals," it is sufficient to pass the Gate:

- **Strong Signal 1: Hardcoded address (PUSH20)**  
  A `PUSH20 0x...` appears in the core path of `transfer/transferFrom`, and this address enters the "credit write chain," strongly suggesting a **fixed recipient/black hole/tax/backdoor address**.

- **Strong Signal 2: 1a Debit chain (sender balance)**  
  Common pattern: `SHA3 → SLOAD → SUB → ... → SSTORE`  
  When delivering, you must specify: **which object was debited** (sender/some key), how much was debited, and under what conditions.

- **Strong Signal 3: 1b Credit chain (recipient balance)**  
  Common pattern: `PUSH20 <addr> → SHA3 → SLOAD → ADD → SSTORE`  
  When delivering, you must specify: **which object was credited** (if not `to=settlement object`, the Gate conclusion is directly B).

> If the same path contains both "1a debit from sender + 1b credit to fixed address," this is the hardest evidence for the Write-object-first Gate: **Ostensibly `to=Pair`, but the actual credit object was overwritten**.

#### 3.6.4 "Only Triggered for Pair" Identification Signals (Used to Explain Trigger Conditions, Not to Replace Write Evidence)

When you suspect a token only triggers special logic in AMM scenarios, look for these combination signals to explain "why the overwrite occurs when targeting Pair":

- `EXTCODEHASH/EXTCODESIZE` (identifying contract type/code hash)
- `STATICCALL` to Router/Factory (e.g., `factory()` / `WETH()` / `getPair()`)
- caller/context checks (`CALLER/ORIGIN`, etc.)

These signals are used to complete the "trigger conditions" but **cannot replace the SSTORE-level evidence of 1a/1b**.

#### 3.6.5 Minimum Deliverable Template (Recommended to Copy Directly)

```text
Gate: Write-object-first
Status: PASSED
Conclusion: B (not credited to settlement object)

Evidence-1a (debit write object):
- function: transfer(...)
- SSTORE chain: SHA3 -> SLOAD -> SUB -> SSTORE
- object: sender balance mapping key = <...> (or sender address semantics)

Evidence-1b (credit write object):
- function: transfer(...)
- hardcoded recipient: 0x...
- SSTORE chain: PUSH20 0x... -> SHA3 -> SLOAD -> ADD -> SSTORE
- object: fixed address balance mapping key = <...>

Read anchor:
- sync()/getReserves reads dust = 502 (0x1f6)

Trigger:
- reserves updated -> swap pricing uses extreme reserve -> outputs WBNB

Profit:
- attacker/EOA receives <amount> WBNB
```

### Phase 4: Evidence Pyramid (Priority)

Proceed in the following priority order (higher = harder evidence):

- **Tier 1 (hardest)**: State write evidence  
  - Critical slots/mappings were written (`SSTORE`, protocol internal state updates)  
  - Written value, write object, trigger conditions
- **Tier 2**: Reproducible numerical evidence  
  - AMM pricing/invariant, Vault share formula, lending health/liquidation threshold, etc., can form a closed-loop recalculation
- **Tier 3**: Event/log evidence  
  - Transfer/Swap/Sync/Mint/Burn, etc. (note: events can be "narrativized" and cannot independently establish causation)
- **Tier 4**: Source code/decompilation evidence  
  - Readable but may have missing blocks/incorrect CFG; must revert to harder evidence for confirmation
- **Tier 5**: Pattern matching/intuition  
  - Can only be used to propose hypotheses, not for final determination

---

### Phase 5: Causal Graph Closure (Write → Read → Trigger → Profit)

The final root cause must be explainable by **a single chain** covering all key phenomena:

- **Write**: Which write changed which critical state (balance/reserve/share/price/permission bit)
- **Read**: Which component (pair/vault/oracle) read what at the critical moment (or received a fabricated return value)
- **Trigger**: What the protocol executed based on that reading (swap pricing, liquidation, redemption, lending limit calculation)
- **Profit**: How assets returned to the attacker and formed net profit

If "a key anomaly" is not explained by the closed loop, it means **there is still a missed write point or conditional branch**.

> **Additional closure requirement (when the final profit action is merely an ordinary `swap/redeem/withdraw`):**  
> In addition to `Write → Read → Trigger → Profit`, you must also supplement a "**Preparation/Accumulation/Flush → Extraction**" phase chain:  
> **How was the anomalous state built up step by step before the final monetization?**  
> If this chain is missing, it means you only explained "how the money came out" but have not yet explained "why the root cause holds."

---
> **Confidence Gate (Phase 5.5)**: Moved to `ATTACK_TX_ANALYSIS_SPEC.md`.

### Phase 6: Output Reproducible Conclusions (Audit/Fix-Friendly)

Recommended mandatory delivery structure (for reuse and post-mortem review):

- **One-sentence root cause**: Must be actionable and unambiguous
- **Trigger conditions**: Prerequisite state/parameters/call ordering/permission relationships
- **Key evidence (3–6 items)**: Trace snippets, critical return values, critical write points, critical formula closures
- **Minimum reproduction steps (5–10 steps)**
- **Remediation recommendations**:
  - Contract-side: Validation/ordering/guard/formula correction/whitelist
  - Protocol-side: Use more robust oracle/price sources, restrict suspicious token behavior
  - Monitoring-side: Anomaly indicator alerts (see below)
- **Detection rules (monitoring indicators)**: Reserve jumps, share change rate, anomalous callbacks, caller-dependent views, etc.

---

## Post-Deep-Dive Phase 7: Reverse Engineering, Unified PoC, and RPC Replay

This stage executes **after** `ATTACK_TX_ANALYSIS_DEEP_DIVE.md` completes.

Its purpose is to turn the analytical conclusion into an attacker-contract-centered exploit reconstruction:

- Read **all** materials under `transactions/<tx>/`, including `analysis/result.md`
- Reconstruct the attacker contract logic using verified source or decompiled output
- Treat **reverse engineering + PoC generation as one task**
- Attempt replay against RPC at the **attack block context**, not the latest state

### Mandatory Deliverables

- `Attack Contract Set`: attacker EOA, attacker contracts, primary attack contract, supporting contracts
- `Reverse Engineering Notes`: entry functions, key branches, hardcoded addresses, required approvals/balances
- `Minimal PoC`: preconditions + ordered call sequence + per-step purpose
- `RPC Replay at Attack Block`: replay anchor, replay method, replay verdict, matched/divergent evidence

### Replay Constraint

When reproducing the exploit, use the attack transaction's block as the time anchor. Prefer the transaction's **pre-state within the same block**; if unavailable, use the closest RPC-supported approximation and state the gap explicitly.

### Output Location

Append the PoC and replay sections to `transactions/<tx>/analysis/result.md`.

For the execution checklist and prohibitions of this stage, see `ATTACK_TX_ANALYSIS_POC_REPLAY.md`.

---

## LLM-Friendly "Slicing Strategy" (Avoiding Ingesting the Entire Trace)

- **Slice by profit path**: Retain only the call subtree directly related to "final asset reflow"
- **Slice by anomaly point**: A window of 20–50 calls before and after the anomaly occurrence
- **Slice by responsibility**: One group for AMM, one for Vault, one for Oracle, one for Token, one for Proxy

The goal is to make each round of input answer one clear question:  
**"Which write caused this anomaly?"** or **"Can this return value be influenced by caller/conditions?"**

---

## LLM-Friendly "Bytecode Forensics" Playbook (No Manual Assembly Reading Required)

When a contract is **unverified**, decompilation is **incomplete/untrustworthy**, or you suspect "adversarial token/fabricated readings," the following **feature-extraction-based** bytecode analysis workflow is recommended. The goal is not to have humans read instructions line by line, but to have the LLM/script perform "pattern recognition + evidence anchoring."

### 1) First Locate Function Entries (selector → entry PC)

A common EVM dispatcher exhibits patterns like: `PUSH4 <selector> EQ PUSH2 <dest> JUMPI`.  
Approach:

- **Scan the runtime bytecode** for `PUSH4` + `EQ` + `JUMPI` structures to obtain the selector-to-entry `PC` mapping
- Pin down the entries of key functions first, for example:
  - ERC20: `transfer(0xa9059cbb)`, `balanceOf(0x70a08231)`, `transferFrom(0x23b872dd)`, `approve(0x095ea7b3)`
  - AMM: `swap`, `sync`, `getReserves`
  - Vault: `deposit/mint/withdraw/redeem`
  - Oracle: `latestAnswer/consult/getPrice`

**Significance**: Avoid "getting lost in global bytecode." Once entries are established, you only need to disassemble a **small window** near the entry for feature extraction.

---

### 2) Separate "Read/Write": Prioritize Finding Writes (SSTORE-first)

For exploits, the hardest evidence is usually "who wrote what state." At the bytecode level, you can use the following patterns to quickly locate critical writes:

- **Mapping writes** common pattern:
  - `... MSTORE ... CODECOPY(<KEY>) ... SHA3 ... (SLOAD) ... (ADD/SUB) ... SSTORE`
  - Where `<KEY>` is often processed by the compiler/decompiler as "CODECOPY a 32-byte constant from the code region" (e.g., the salt/seed of a mapping slot)
- **Total supply/counter writes** common pattern:
  - `SLOAD ... ADD/SUB ... SSTORE` (not necessarily with `SHA3`)
- **Permission bit/toggle writes**:
  - Low-bit bitmask `AND/OR/SHR/SHL` + `SSTORE`

> You don't need to understand every stack transformation; as long as you extract "the KEY before and after `SHA3`, the location of `SSTORE`, and any nearby constants/addresses," you can form usable evidence.

---

### 3) Three "Strong Signals" for Rapid Identification of Adversarial Logic

- **Hardcoded addresses (PUSH20)**:  
  For example, `PUSH20 0x...` appearing near transfer/mint/redeem paths strongly suggests a "fixed recipient/black hole/team/fee/backdoor address."

- **Event topic constants (especially Transfer/Approval)**:  
  The ERC20 `Transfer` topic is `ddf252ad...`, `Approval` is `8c5be1e5...`.  
  In some bytecodes, these topics appear as 32-byte constants (possibly fetched via `CODECOPY`), then used for `LOG3/LOG4`.  
  **Use**: You can correlate "balance writes" with "event emissions" to confirm which path is doing "real accounting."

- **Caller/contract identification signals (common for DEX special-casing)**:  
  When `CALLER`, `ORIGIN`, `EXTCODEHASH`, `EXTCODESIZE`, `STATICCALL router/factory` appear in combination, it often means "special branch for trading pairs/routers/specific contracts."

---

### 4) Close the Loop Between Bytecode Evidence and Trace Evidence (Minimum Closure)

Recommended fixed procedure of 4 steps:

- **Pick 3 points from the trace**:
  - Trigger point: The critical function called by the attacker (e.g., `transfer(to=pair)` / `deposit` / `borrow`)
  - Anomaly point: The call where the protocol reads an anomalous value (e.g., `pair.balanceOf(pair)=502` / abnormal `getReserves`)
  - Profit point: The attacker's asset reflow (swap output, withdraw, liquidation proceeds)
- **Find the corresponding function entries in the bytecode** (Step 1)
- **Find the SSTORE chain near that function** (Step 2)
- **Verify "object" consistency**: The write object (which address/which mapping key) must be able to explain the anomaly point in the trace

---

### 5) Deliverable Template: Minimum Bytecode Forensics Report

Recommended LLM/script final output fields to avoid "only telling a story":

- **selectors → entry PCs**: List critical function entries
- **Write point inventory (SSTORE sites)**: For each write point, provide:
  - Location (PC or instruction window)
  - Neighboring features: Whether `SHA3` is present, whether `PUSH20` appears, whether accompanied by `LOG3/LOG4`
  - Inferred object: Likely balances mapping / totalSupply / flag
- **Hardcoded address inventory** (near which path they appear)
- **1–2 strong alignment evidence items with the trace** (e.g., "this branch redirects the recipient to a fixed address")

---

## Modular Checklists for Common Attack Categories

### 1) AMM / DEX
- **Key objects**: `swap/sync/getReserves/balanceOf(pair)`, flash swap callbacks, fee-on-transfer
- **Typical checks**:
  - **Reserve/balance consistency**: Are `reserve` and `balance` consistent; is there an anomalous jump after `sync()`
  - **Special token behavior**: Does `transfer` to Pair redirect/tax; is `balanceOf` caller-dependent
  - **TWAP window**: Is it too short; is spot price used as oracle
  - **Mandatory correction workflow**: For AMM + adversarial token, the three-step "first verify credit object, then read deception, then settlement closure" is detailed in `ATTACK_TX_ANALYSIS_SPEC.md`.

#### 1.1) Large Swap-Driven Attacks (General Module)
When you observe "batch liquidations/many third parties deteriorating simultaneously," you must assume that a "**price-driving action**" exists (typically one or several large swaps), and execute the minimum checks:
- **Locate candidate swaps**: Scan/search the trace for these function signatures (any match suffices):  
  - `exchange(...)` (common in Curve/stable pools)  
  - `swap(...)` (UniswapV2/V3/custom AMM)  
  - `swapExactTokensForTokens(...)` (Router)  
- **Sort by size**: Sort candidate swaps by input amount (amountIn/dx) and output amount (amountOut/dy), list at least Top-3, and mark their pool address and coin index (e.g., `i/j` or path).
- **Align "price-driving actions" with the "Degradation Chain"**: Did the swap occur before or after the "exchange rate/oracle input change"? Did it immediately precede a banded AMM `exchange`/`active_band`/user tick read? Was it followed by `users_to_liquidate`/batch `liquidate`?

- **Mandatory coin resolution (avoid "i/j without grounding")**:  
  Whenever Top swaps contain Curve-style `exchange(i,j,...) / exchange_underlying(i,j,...)`, you must map `i/j` to "specific token in/out" (at minimum provide token addresses), and state the evidence source (coins()/underlying_coins()/inferred from adjacent Transfer, etc.).  
  This is a universal requirement: otherwise you cannot reliably produce verifiable conclusions like "alUSD-sDOLA pool large swap."

> **Key reminder (avoid misjudgment)**:  
> - "Liquidation settlement actions" (`withdraw`/`transferFrom`) explain "how value was extracted," but cannot replace "why it became extractable."  
> - If you claim an internal `exchange` as a push_action, you must simultaneously provide the Top list of external swaps and explain why external swaps are not the primary driving action (otherwise this constitutes skipping a step).

### 2) Lending / Vault / Share
- **Key objects**: `totalAssets/totalSupply`, share mint/redeem formula, rounding, donation attacks
- **Typical checks**:
  - **Share pricing formula reproducible closure**: Can it be manipulated via donation/instantaneous price manipulation
  - **Ordering**: Transfer before minting shares? External call before state update?
  - **ERC4626 mandatory checks (general and high-signal)**: If collateral/pricing factors involve ERC4626 `convertToAssets/convertToShares` or share tokens:
    - Did `deposit/mint/withdraw/redeem` occur within the same tx (affecting `totalSupply` and share burn/mint)
    - Is there a "assets increase but shares don't" path (donation/third-party accounting/transfer into vault without minting shares)
    - Is there a "shares change but assets don't change equivalently" path (redeem/withdraw/restake/reward release timing)
    - If oracle/health directly uses `convertToAssets`, primarily suspect "share pricing can be atomically inflated/deflated," and decompose its source (`totalAssets` changed? `totalSupply` changed? Both changed?)

#### 2.1) ERC4626 "Dual Knob" Manipulation (General Module)
When you observe share pricing jumping within the same tx, you must simultaneously check both types of knobs (neither may be omitted):
- **Assets knob (affecting totalAssets/asset accounting)**: Donation, third-party accounting, instant reward/interest accrual, underlying assets transferred directly in without minting shares.
- **Supply knob (affecting totalSupply)**: `redeem/withdraw` (burning shares), `mint/deposit` (issuing shares), and any path that "mints/burns shares but doesn't move assets as expected" (including stake/unstake/wrapper contracts).
Delivery requirement: Write a one-sentence summary of "which knob is primarily used in this case + whether the other knob is also involved," and provide anchor points aligned to the trace (call point + jump reading).

> **General reinforcement (prevent supply knob from being "hand-waved away")**:  
> If you mention that redeem/mint/deposit/withdraw affected share pricing, you must simultaneously provide `totalSupply()` before/after reading anchor points (within the same tx), and list all supply ops (redeem/mint/deposit/withdraw) call anchor points and their order of magnitude. Otherwise, the supply knob may only be written as a "pending hypothesis" and cannot be included in the root cause main chain.

### 2.5) Liquidation / Position Migration
- **Key objects**: `liquidate`, batch liquidators, `health`/`health_factor`, `users_to_liquidate`, LLAMMA/banding mechanism-related `exchange`, oracle input components (pool price, vault rate, aggregator)
- **Typical checks** (by priority):
  - **Is liquidation the primary profit source**: Whenever the transaction contains liquidation/batch liquidation of multiple third-party addresses, treat it as the mainline by default and first draw the "Victim Subgraph"
  - **Why did they become liquidatable**: At minimum answer one of the following three (may coexist):
    - Oracle input change causing valuation deterioration (oracle jump / component change)
    - Position collateral composition passively migrated (LLAMMA bands causing swap from one type of collateral to another)
    - Borrowing/interest/fees causing health to cross the line (close factor/fee/penalty)
  - **Align price-driving actions with position changes**: Large swap/price driving → (bands/mechanism internal repositioning) → health drops below threshold → liquidation occurs → value flows back to attacker

#### 2.6) Banded AMM/LLAMMA Position Migration Quick Reference (General Module)
When the protocol components include "banded AMM/LLAMMA/segmented market-making," the following three questions must be answered (convergence is not permitted without them):
1) **What is the driving action?** (Which swap/exchange drove the price/pool ratio)  
2) **Where did the migration occur?** (Which `exchange`/band-related call caused position x/y composition change; provide at least 1 call anchor point)  
3) **How did the migration affect health?** (Collateral composition skew/valuation input change causing health to cross the line)  
Output need not be fully recalculated, but must chain the three questions into a chronologically clear sequence, with each question corresponding to at least one trace anchor point.

> **General correction**: If you claim "continuous repositioning/position migration under the bands mechanism caused users to deteriorate," your anchor points must come from "mechanism actions/reads/writes before liquidation" (e.g., `exchange`/tick/band state change/user share callback reads), not merely citing "withdraw after liquidation occurs."

### 3) Oracle / Price
- **Key objects**: spot vs TWAP vs Chainlink, staleness, update permissions, heartbeat
- **Typical checks**:
  - **Can price be moved by a single transaction**
  - **Is data stale/rollback-able**

### 4) Permission / Signature / Permit
- **Key objects**: owner/admin, upgrade, nonce, domain separator, replay
- **Typical checks**:
  - **Missing validation / incorrect nonce management**
  - **Permission bypass via delegatecall context**

### 5) Reentrancy / Callback / Hook
- **Key objects**: External call sites, fallback, ERC777/callbacks, cross-contract ordering
- **Typical checks**:
  - **"External call before state update" pattern**
  - **Missing ReentrancyGuard / reentrancy lock**

### 6) Non-Standard ERC20 / Proxy (Adversarial Token)
- **Key objects**: Does `transfer` overwrite the recipient, is `balanceOf` caller-dependent, special-casing for Pair/Router
- **Typical checks**:
  - **Are transfers to Pair redirected to a fixed address/black hole/team**
  - **Does the same `balanceOf(pair)` return different values under different callers**
  - **Does it depend on `CALLER/EXTCODEHASH` or external probing (router/factory)**

### 7) Tokenomics / Deflationary / Reward Distribution (Business Logic Composition)
- **Key objects**: `pending/reward/fee/burn/debt/distributor` accumulation states, `claim/flush/settle/distribute/sync` public maintenance entry points, and special branches triggered by `from/to/receiver/path`
- **Typical checks**:
  - **Is the same state bucket read/written by multiple mechanisms**: e.g., `deposit` increments, `sell` increments, `claim/flush` clears, `sync` settles
  - **Is there a "individually reasonable, combined dangerous" design**: Multiple mechanisms all act on the same Pair/Vault/Oracle reading or the same settlement object
  - **Can it be atomically chained in a single tx**: Missing access control, cooldown, epoch/rate limit, or public maintenance functions that can be immediately triggered by anyone
  - **Is a special receiver/path parameter selecting a branch**: e.g., `to=router/pair/dead/distributor`
  - **When encountering such scenarios, strongly recommend executing Module H (Multi-Mechanism Business Chain and Accumulation Bucket Flush)**

---

## Case Template: When You "Guessed Wrong First," How to Quickly Correct (Especially Suited for LLMs)

This section specifically summarizes how to abstract "your analysis process after you gave an answer" into reusable patterns. The core idea is: **Don't get entangled with narrative—immediately pin down the divergence point with minimum evidence**.

### Scenario: Same `balanceOf(pair)` Inconsistent Under Different Callers

This phenomenon is commonly caused by two mutually exclusive root causes (must be retained in parallel):

- **Hypothesis A: Read-type deception**  
  `balanceOf` returns different values for different callers/conditions (e.g., returns 502 for the Pair contract, returns a large number for external callers)
- **Hypothesis B: Write-type ledger modification/redirection**  
  `transfer(to=pair)` did not actually credit the Pair, but redirected to a fixed address/taxed/wrote to a different key, causing the Pair's actual balance to be very small (e.g., only dust=502 remaining)

### Minimum Falsification Order (Recommended)

- **Step 1 (mandatory gate)**: Verify the "credit object" of `transfer(to=pair)` (Write-object-first)  
  - Answer only one question: **"Who was the balance credited to?"**  
  - If you find that "debit from sender + credit to fixed address/not-to" shows write object inconsistency, directly classify as **Write-type redirection/ledger modification** (this is root cause-level evidence).

- **Step 2 (then do)**: Verify whether `balanceOf` is caller-dependent  
  - Look for `CALLER/EXTCODEHASH` branch signals in the `balanceOf` entry window  
  - Cross-validate with trace: Does the same input consistently reproduce differences under different callers

### Why Is This Order More Robust?

Because it shifts the question from "what was read (may be fabricated)" to "where was it written (hardest)."  
In adversarial tokens, "reads" are easier to manipulate, while "writes" are harder to hide (they ultimately must land on certain `SSTORE` operations).

### Correction Checklist: Most Common LLM Drift Points (Turning Post-Mortems into Rules)

Below are "mandatory correction rules" distilled from real analysis post-mortems. Their function is: when you see phenomena that "look like an attack" (e.g., critical readings fluctuating wildly, the same asset flow not matching at different points), don't let the narrative lead you astray—prioritize pinning down the divergence point with minimum evidence.

- **First write a "core contradiction" sentence** (compress the massive trace into one conflict to explain)  
  Typical high-signal format (using placeholders to avoid binding to specific protocols/function names):
  - `A certain "write/transfer/update" action shows success` **but** `the immediately following "read/settlement/update" action that uses it as a critical dependency reads a value without corresponding change`  
  - `Events/receipts show A→B transfer completed` **but** `the state reading that the protocol's subsequent calculation depends on still looks like "not received/only dust received/anomalously little received"`  
  This core contradiction sentence forces the problem onto the hardest question: **Where was the write actually written to? Whose ledger was modified?**

- **Mandatorily maintain a "competing explanation set"; single-point determination is prohibited**  
  In adversarial contract/asset scenarios, the two most common mutually exclusive explanations must be retained in parallel until falsified:
  - **Write type**: The write object was overwritten (redirection, written to a different key/slot/account, conditional branching causing "ostensible success but no credit to target")
  - **Read type**: The reading was fabricated (caller/condition dependency, returning different values for different queriers, returning different values for the same input at different time points)

- **Falsification order is fixed: Write before Read (SSTORE-first)**  
  Even if you temporarily skip instruction-level analysis, organize checks and narrative in this order:
  - First verify Write type: Did the critical write actually change "the object that should have been changed" (balance/reserve/share/permission bit/counter, etc.)? If the immediately adjacent critical read still looks like "nothing changed," primarily suspect "wrong object written/written elsewhere"
  - Then verify Read type: Does the critical read have caller/condition dependency? (This explains "why the reading changes" but is usually not the primary reason for "why the write and read don't match")

- **Demote "phenomenal evidence"; do not let it dominate the root cause**  
  For example, "a very large critical reading appearing later" only indicates anomalous behavior and **is not equivalent to** "the root cause is Read-type deception."  
  In adversarial scenarios, the most stable anchor is always: **the reading directly related to the protocol's critical state update/settlement**, and whether the immediately preceding write action is self-consistent.

- **Output must include confidence annotation and minimum falsification action**  
  Before obtaining hard evidence of the credit object (write point/conditional branch), avoid writing any single hypothesis as a definitive conclusion. Recommended fixed output:
  - `hypotheses`: At least two mutually exclusive explanations (Write/Read)
  - `minimal_check`: The shortest falsification action for each explanation (prioritize low-cost, prioritize write-related)
  - `confidence`: low/medium/high (and state "what evidence is still needed to elevate to high")

> **Mandatory sentence patterns**: To prevent skipping steps, these have been moved to `ATTACK_TX_ANALYSIS_SPEC.md`.

---

## More Complete Attack Type Coverage (Recommended to Gradually Add to Your Project)

If you want this methodology document to become a "universal arsenal," the following categories' checklists are recommended for future addition (outlines provided here):

- **Cross-chain/Bridge**: Message verification, light client/multisig threshold, replay, payload parsing, chain ID/domain separation
- **Governance/Permission Upgrade**: Timelock bypass, proposal execution ordering, upgradeTo/initialize reentrancy, storage slot conflicts
- **Liquidation/Lending Edge Cases**: Price source staleness, close factor, rounding, bad debt absorption mechanism, batch liquidator misuse/exploitability, health calculation oracle components atomically manipulable (including ERC4626 redemption rate)
- **Read-only Reentrancy**: View functions reading dependent on externally mutable state, causing readings to be manipulated within the same tx
- **MEV Sandwich**: Not a contract vulnerability but causes asset loss; identifying "front-running/back-running transactions" and price impact

## Output Templates (Recommended to Copy and Use Directly)

### 1) One-Sentence Root Cause

- **Root cause**: \<one sentence, including "which contract/function/condition → wrote what incorrect state or fabricated what reading → caused which protocol component to misjudge"\>

### 2) Trigger Conditions

- **Prerequisite state**: \<funds/authorization/pool state/price window, etc.\>  
- **Key parameters**: \<amount, path, to, deadline, mode, etc.\>  
- **Call ordering**: \<A→B→C, with emphasis on callback and reentrancy entry points\>

### 3) Key Evidence (3–6 items)

- **Evidence 1 (write)**: \<who wrote which state where, written value/object\>  
- **Evidence 2 (read)**: \<which component read what anomalous value\>  
- **Evidence 3 (trigger)**: \<how the protocol executed a critical action based on that reading\>  
- **Evidence 4 (profit)**: \<how assets returned to the attacker\>
> For adversarial token/AMM scenarios, the "write evidence 1a/1b decomposition" is a mandatory specification; see `ATTACK_TX_ANALYSIS_SPEC.md`.

> **Supplement (general)**: If you write "price changed from A to B" (e.g., `price_w`/`price_oracle`/share price) in the body text, you must provide **before/after reading anchor points and raw values** in the evidence; otherwise do not write specific numerical changes.

### 4) Minimum Reproduction Steps (5–10 steps)

- **Step 1**: \<Setup/borrow/flashloan\>  
- **Step 2**: \<Manipulate state or fabricate reading\>  
- **Step 3**: \<Trigger protocol misjudgment\>  
- **Step 4**: \<Arbitrage/drain\>  
- **Step 5**: \<Repay/settle/pocket profit\>

### 5) Remediation Recommendations

- **Contract-side**: \<Validation/ordering/guard/whitelist/formula correction\>  
- **Protocol-side**: \<More robust oracle, restrict suspicious tokens, restrict extreme parameters\>  
- **Monitoring-side**: \<Alert rules\>

---

## "Per-Round Prompt Skeleton" for LLMs (Trim as Needed)

You can limit each round's task to "answering one question," for example:

- **Question A (Write before Read)**: Find the most likely state write point causing the anomaly, and list 2–3 competing explanations with minimum falsification checks.
- **Question B (adversarial readings)**: Determine whether a certain view/return value has caller dependency or conditional deception, and provide reproducible evidence.
- **Question C (closure)**: Chain Write→Read→Trigger→Profit into a single unique causal chain, and indicate the evidence source for each link.

Recommended fixed output fields per LLM round (to facilitate convergence):

```json
{
  "actors": [],
  "assets": [],
  "anomalies": [],
  "hypotheses": [
    {"name": "...", "type": "Write|Read|Constraint|Order|Dependency|Math|Proxy", "minimal_check": "..."}
  ],
  "evidence": [],
  "next_actions": [],
  "confidence": "low|medium|high"
}
```

---

## When to Stop (Convergence Stop Conditions)

The root cause can be considered "methodologically closed" when the following conditions are met:

- **At least one critical write point has been located and explained** (who wrote, where, what, under what conditions)
- **All key anomalous phenomena can be explained by a single causal chain** (no "residuals")
- **The profit path can be recalculated to closure** (fund flow consistent with key formulas)
- **The conclusion is reproducible** (the attack can be re-described following the minimum steps)
