# Case Study — `tx 0x767d8a0f…f312` (BSC, Lista / FLAP Vault Drain)

This case study walks through the **post-deep-dive stage** for this transaction:

1. Reverse engineering the attacker contracts
2. Writing a minimal, trace-aligned Foundry replay harness
3. Forking against the **exact tx-prestate** on BSC using `anvil --fork-transaction-hash`
4. Making the replay **deterministic** with hard-coded on-fork assertions
5. Running a **read-only risk upper bound** evaluation (defensive / auditor-only)

All steps below are reproducible from this repo. They are intentionally small so
they can be driven end-to-end by a one-shot codex run.

---

## 1. Scope

- **Tx hash**: `0x767d8a0f2a6c2b5d1e3466bac47722a4f86a2bb9e41260dd52d274a9f100f312`
- **Network**: BSC Mainnet (chainId 56)
- **Block**: `92_821_762`, tx index `102`
- **Analysis document (prerequisite)**: `transactions/0x767d.../analysis/result.md`
  (must already contain root cause, Write→Read→Trigger→Profit chain, and
  Deep Root Cause section before this stage starts)

Deepest root cause (from `result.md`): `ListaDAOLiquidStakingVault._pendingTaxReward()`
uses `accumulativeDividendOf(user) / totalDividendsDistributed()` from the
Dividend contract as a proxy for slisBNB entitlement — allowing a flash-backed
attacker to inflate the ratio and drain historical slisBNB.

---

## 2. Artifacts added in this stage

| Path | Purpose |
|------|---------|
| `foundry.toml` | Minimal Foundry config pinned to `solc 0.8.24`, `evm_version = cancun`, output under `replay/` |
| `replay/src/Tx767dInterfaces.sol` | Minimal interfaces used by the replay (ERC20, WBNB, PancakePair, PancakeRouter, PancakeV3SwapRouter, Dividend, Vault) |
| `replay/src/Tx767dAttack.sol` | `Tx767dReplayLauncher` + `Tx767dReplayWorker` — exploit sequence re-expressed in Solidity |
| `replay/test/Tx767dReplay.t.sol` | 5 Foundry tests: 2 document known blockers, 1 seeded simulation, 1 exact prestate replay, 1 read-only risk upper bound |
| `transactions/0x767d.../analysis/result.md` (§ RPC Replay + § Risk Upper Bound) | Human-facing output of this stage |

---

## 3. End-to-end run (one-shot)

```bash
# 0. prerequisites
source venv/bin/activate
export BSC_RPC_URL="https://bnb-mainnet.g.alchemy.com/v2/<KEY>"

# 1. pin a local node to the exact tx prestate
anvil \
  --fork-url "$BSC_RPC_URL" \
  --fork-transaction-hash 0x767d8a0f2a6c2b5d1e3466bac47722a4f86a2bb9e41260dd52d274a9f100f312 \
  --port 8546 \
  --timeout 120000 --retries 20 --fork-retry-backoff 1000 --no-rate-limit

# 2. run the full replay + defensive evaluation
forge test -vv
```

Expected output (stable, taken from this repo):

```
[PASS] testReplayAttackFromParentBlockForkShowsSameBlockBlocker()            # documents blocker A
[PASS] testReplayAttackFromAttackBlockEndStateShowsMutatedStateBlocker()     # documents blocker B
[PASS] testSimulateCoreExploitOnParentBlock()                                # fallback when exact prestate unavailable
[PASS] testReplayAttackFromExactTxPrestate()
  exact-replay: vault_slis_delta        = 3.802931882574188786
  exact-replay: profit_wnb              = 2.335548647317693359
  exact-replay: totalClaimed_before     = 9377178447088055634
  exact-replay: totalClaimed_after      = 13180110329662244420
[PASS] testRiskUpperBoundAtTxPrestate()
  risk: prestate_vault_slis_balance     = 3.807430454311865050
  risk: prestate_taxAccumulativeSlis    = 13.184608901399920684
  risk: prestate_totalClaimed           = 9.377178447088055634
  risk: max_drainable_cap               = 3.807430454311865050
  risk: drained_in_this_tx              = 3.802931882574188786
  risk: residual_after_this_tx          = 0.004498571737676264
  risk: drained_bps_of_cap              = 9988
```

---

## 4. Minimal PoC sequence (encoded in `Tx767dReplayLauncher` / `Tx767dReplayWorker`)

1. Flash-borrow `11.3 WBNB` from Pancake pair `0xbC42...Efa5` (`SKYAI/WBNB`).
2. Fund a worker with the flash amount.
3. Swap `10 WBNB -> FLAP` on PancakeRouter. This fires
   `FlapTaxTokenV3._afterTokenTransfer()` which writes a large
   `userInfo[worker].share` into the Dividend contract.
4. Call `Dividend.deposit(1.2 WBNB)` — permissionlessly increments
   `magnifiedDividendPerShare` and `totalDividendsDistributed`, crediting
   almost all of it to the worker because it now dominates `totalShares`.
5. Call `ListaDAOLiquidStakingVault.claimReward()`. The vault reads
   `accumulativeDividendOf(worker)` and `totalDividendsDistributed()`, and
   transfers `taxAccumulativeSlis * userDividend / totalDividends` slisBNB
   to the worker (≈ **3.802931882574188786 slisBNB**).
6. Swap `slisBNB -> WBNB` through PancakeV3 (`fee = 100`).
7. `Dividend.withdrawDividends()` to recover most of the 1.2 WBNB deposit.
8. Sell FLAP back to WBNB, repay `11.334002006018054162 WBNB` to the pair,
   keep the residual profit of **2.335548647317693359 WBNB** in the launcher.

Every one of these steps is grounded in the trace in `transactions/0x767d.../trace/`.

---

## 5. Test matrix (what each test proves)

| Test | Fork source | What it proves |
|------|-------------|----------------|
| `testReplayAttackFromParentBlockForkShowsSameBlockBlocker` | remote RPC `bsc@block-1` via `vm.createSelectFork("bsc", BLOCK-1)` | You **cannot** just reuse state from `block-1` — some tokens (e.g. `SKYAI`) are `NotActivated` in that prestate. Blocker A is encoded as `expectRevert`. |
| `testReplayAttackFromAttackBlockEndStateShowsMutatedStateBlocker` | remote RPC `bsc@block` | You **cannot** replay from the end-of-block state — the attack already ran, accumulators are mutated. Blocker B is encoded as `expectRevert`. |
| `testSimulateCoreExploitOnParentBlock` | remote RPC `bsc@block-1`, seeded via `vm.deal` + `simulateWithoutFlash` | Demonstrates the **core exploit primitive** when exact prestate is unavailable: bypass the flash callback, inject WBNB, still extract slisBNB. |
| `testReplayAttackFromExactTxPrestate` | local `anvil --fork-transaction-hash` at `127.0.0.1:8546` + `vm.roll(ATTACK_BLOCK)` | Exact **tx-prestate** replay. Hard-coded assertions match on-chain values to 1 wei. |
| `testRiskUpperBoundAtTxPrestate` | same local anvil | **Read-only** defensive evaluation. Computes `maxDrainable = min(vaultBalance, taxAccumulativeSlis - totalClaimed)` and compares to the actual drain. |

---

## 6. Why the exact prestate fork uses a local anvil

`vm.createSelectFork("bsc", ATTACK_TX_HASH)` fails against the current BSC
remote backend with:

```
transaction validation error: authorization list not supported
```

`anvil --fork-transaction-hash <tx>` replays the block locally **up to but not
including** the target tx, so the resulting local chain exposes exactly the
pre-state we need. Foundry tests then point at `http://127.0.0.1:8546` and
call `vm.roll(ATTACK_BLOCK)` so `block.number` matches the real environment.

The recommended anvil flags (`--timeout 120000 --retries 20
--fork-retry-backoff 1000 --no-rate-limit`) exist because without them we hit
transient `connection closed before message completed` errors during heavy
storage fetches from Foundry.

---

## 7. Deterministic assertions

The replay test encodes the exact on-fork outputs as constants so future
regressions are obvious:

```solidity
uint256 internal constant EXPECTED_VAULT_SLIS_DELTA        = 3_802_931_882_574_188_786;
uint256 internal constant EXPECTED_PROFIT_WBNB             = 2_335_548_647_317_693_359;
uint256 internal constant PRESTATE_VAULT_SLIS_BALANCE      = 3_807_430_454_311_865_050;
uint256 internal constant PRESTATE_TAX_ACCUMULATIVE_SLIS   = 13_184_608_901_399_920_684;
uint256 internal constant PRESTATE_TOTAL_CLAIMED           = 9_377_178_447_088_055_634;
```

The exact replay enforces:
- `vaultSlisDelta == EXPECTED_VAULT_SLIS_DELTA`
- `totalClaimedDelta == EXPECTED_VAULT_SLIS_DELTA`
- `profitWbnb == EXPECTED_PROFIT_WBNB`

The risk upper bound test enforces:
- `vaultSlisBal == PRESTATE_VAULT_SLIS_BALANCE`
- `taxAcc == PRESTATE_TAX_ACCUMULATIVE_SLIS`
- `totalClaimed == PRESTATE_TOTAL_CLAIMED`
- `remainingByAccumulator == vaultSlisBal`   (cap binds to balance in this case)
- `EXPECTED_VAULT_SLIS_DELTA <= maxDrainable` (real drain does not exceed the cap)

---

## 8. Risk upper bound result (defensive read)

Using only on-chain values at the tx prestate:

- `max_drainable_cap = min(SLisBNB.balanceOf(vault), taxAccumulativeSlis - totalClaimed)`
  = `3.807430454311865050 slisBNB`
- `drained_in_this_tx = 3.802931882574188786 slisBNB`
- `drained_bps_of_cap = 9988` (99.88 %)
- `residual_after_this_tx = 0.004498571737676264 slisBNB`

Interpretation: the attacker captured essentially all of the available slisBNB
reachable through the vulnerable formula at this specific block. The residual
gap (~0.0045 slisBNB) reflects precision losses in the vault's
`totalEntitled * userDividend / totalDividends` calculation.

---

## 9. Reusable methodology

This case study is the concrete instance. The reusable "how to do this for
any new tx" lives in:

- `docs/ATTACK_TX_ANALYSIS_POC_REPLAY.md` — what the PoC/replay must contain
- `docs/ATTACK_TX_ANALYSIS_FORK_HARNESS.md` — how to build the Foundry + anvil
  fork harness, `.t.sol` layout, blocker-documenting tests, deterministic
  assertion pattern
- `docs/ATTACK_TX_ANALYSIS_RISK_BOUND.md` — how to design and encode the
  read-only risk upper bound evaluation

Those three documents, combined with this case study, let codex run the full
pipeline on a new tx without needing any prior context from this chat.
