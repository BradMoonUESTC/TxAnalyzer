# Risk Upper Bound Evaluation (Defensive, Read-Only)

> Executed immediately after `ATTACK_TX_ANALYSIS_POC_REPLAY.md` and
> `ATTACK_TX_ANALYSIS_FORK_HARNESS.md`. This document defines a strictly
> **defensive** evaluation: given the vulnerability is exactly as
> described in `result.md`, how much could have been drained at this
> specific tx-prestate — and how does the actual attack compare?
>
> This stage is **not** a search for higher profit. It is an auditor's
> bound sheet: "worst-case under today's state, under the same model."

---

## Purpose

For every analyzed attack tx, the replay stage must answer:

1. Is the real drain close to the theoretical cap? (dosage)
2. Is there still residual risk at the same prestate? (exposure)
3. Which on-chain value is the binding constraint (balance vs accumulator)?
4. Does the recommended fix actually close the cap? (validation)

These answers are a natural by-product of the exact-prestate fork we
already build for the replay test. Adding this stage costs a handful of
read-only RPC calls.

---

## Core Principle: Min-of-Constraints

The upper bound is always the **intersection** of what the protocol logic
allows and what the on-chain inventory can actually deliver:

```
maxDrainableCap = min(
    settlementObject.balance,          // inventory constraint
    accumulator.remaining               // logic-layer constraint
)
```

For the reference case
(`ListaDAOLiquidStakingVault._pendingTaxReward`), the two constraints are:

- inventory: `IERC20(slisBNB).balanceOf(vault)`
- accumulator: `vault.taxAccumulativeSlis() - vault.totalClaimed()`

Both are public views. Both must be read from the **exact tx prestate**
(same local anvil fork used by the replay test).

---

## Mandatory Inputs

1. `transactions/<TX>/analysis/result.md` — must already identify:
   - the settlement object (e.g. which balance is extracted)
   - the accumulator(s) the vulnerable formula reads from
2. A live local anvil pinned to the tx prestate (see
   `ATTACK_TX_ANALYSIS_FORK_HARNESS.md`).
3. The exact actual drain value already captured by the replay test
   (`EXPECTED_<SETTLEMENT_OBJECT>_DELTA`).

If any of these is missing, do not compute a risk bound. State the gap
and stop — a guessed bound is worse than no bound.

---

## Required On-Fork Measurements

Per attack tx, read **all** of the following from the prestate fork and
emit them via `emit log_named_*` in the risk test:

| Measurement | Example (reference tx) | How to read |
|-------------|------------------------|-------------|
| `prestate_<object>_balance` | `SLisBNB.balanceOf(vault)` = 3.807430454311865050 | `IERC20Like(token).balanceOf(holder)` |
| `prestate_<accumulator>_total` | `vault.taxAccumulativeSlis()` = 13.184608901399920684 | direct getter |
| `prestate_<accumulator>_claimed` | `vault.totalClaimed()` = 9.377178447088055634 | direct getter |
| `remaining_by_accumulator` | 3.807430454311865050 | `total - claimed` |
| `max_drainable_cap` | 3.807430454311865050 | `min(balance, remainingByAccumulator)` |
| `drained_in_this_tx` | 3.802931882574188786 | reuse `EXPECTED_..._DELTA` |
| `residual_after_this_tx` | 0.004498571737676264 | `cap - drained` |
| `drained_bps_of_cap` | 9988 | `drained * 10_000 / cap` |

Units must match the settlement object (do not mix 18-decimals and raw
wei in the same emit). Use `emit log_named_decimal_uint(key, val, 18)`
for ERC20 amounts.

---

## Required Assertions

The risk test must fail fast if anything the report claims is wrong:

- `balance == PRESTATE_<OBJECT>_BALANCE` (prestate binding)
- `accumulatorTotal == PRESTATE_<ACC>_TOTAL`
- `accumulatorClaimed == PRESTATE_<ACC>_CLAIMED`
- `EXPECTED_<OBJECT>_DELTA <= maxDrainableCap`
  (sanity: the observed drain must not exceed the bound)
- `which constraint binds` — encode explicitly which of
  `balance` or `remainingByAccumulator` is smaller. If both are equal
  (as in the reference tx), assert equality.

Use `==` not `>=`. The point is to pin the prestate so that any upstream
change (reorg, different block, different chain) surfaces as a test
failure rather than a silent drift.

---

## Output Format (append to `result.md`)

Add a new section after `## RPC Replay at Attack Block`:

```markdown
### Risk Upper Bound (at tx prestate)

- `<object>.balance` (prestate): `…`
- `<accumulator>.total` (prestate): `…`
- `<accumulator>.claimed` (prestate): `…`
- `<accumulator>.remaining`: `…`
- `maxDrainableCap` = `min(balance, remaining)` = `…`
- `drainedInThisTx` = `…` (`<bps>` of cap)
- `residualAfterThisTx` = `…`
- Binding constraint: `balance` | `accumulator` | `both (equal)`

Repro evidence: `replay/test/Tx<short>Replay.t.sol::testRiskUpperBoundAtTxPrestate`
```

---

## Optional: Fix Validation Pass

When a remediation is proposed in `result.md` (e.g. swap the vulnerable
formula for `userInfo[user].share / totalShares`), add a second
read-only test that computes the **post-fix** entitlement using the same
prestate reads:

```
entitlementUnderFix = taxAccumulativeSlis * userShare / totalShares
                       - claimed(user)
```

Assert `entitlementUnderFix <= PRESTATE_<OBJECT>_BALANCE / N` for some
sensible bound (e.g. the attacker's legitimate fraction of `totalShares`
pre-flash). This test does **not** execute the fix; it only shows that
the new formula, applied to the same prestate, collapses the cap.

Reserve this pass for cases where the remediation is concrete enough to
express as a pure function. Do not invent a fix just to validate it.

---

## Scope / Prohibitions

1. **Do not use this stage to search for a higher-profit version of the
   attack.** This is a defensive bound, not an optimization target.
2. **Do not relax the prestate pin.** No rolling the fork to a later
   block, no `vm.warp` for bigger accumulators, no `vm.deal` to raise
   inventory. Those would answer a different question ("could it have
   been worse under different conditions?") and belong in a separate,
   clearly-labeled analysis — not in the per-tx result.
3. **Do not publish a bound without `==` assertions on the
   `PRESTATE_*` values.** An unasserted bound drifts silently with
   upstream data.
4. **Do not aggregate across multiple tx hashes** in a single risk test.
   One tx, one test, one bound.

---

## Definition of Done

The risk upper bound stage is complete when **all** of the following are
true:

- A `testRiskUpperBoundAtTxPrestate` exists in the replay test file and
  passes with the same local anvil instance used by the exact replay.
- Every measurement in the table above is emitted via `log_named_*` and
  asserted with `==` against pinned `PRESTATE_*` constants.
- `result.md` has a `Risk Upper Bound (at tx prestate)` section with the
  same numbers and identifies the binding constraint.
- Confidence of the risk bound is recorded as the minimum of:
  - confidence of the root cause in `result.md`
  - confidence of the replay (`reproduced` → high; `partially_reproduced`
    → medium; `blocked` → low).
