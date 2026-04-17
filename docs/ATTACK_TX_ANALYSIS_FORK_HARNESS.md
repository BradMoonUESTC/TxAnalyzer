# Attack-Tx Fork Harness (Foundry + Anvil)

> This document is executed together with `ATTACK_TX_ANALYSIS_POC_REPLAY.md`.
> It specifies the **concrete executable scaffolding** needed to turn the
> PoC/Replay stage into a runnable Foundry test suite anchored to the exact
> tx prestate. It is deliberately mechanical so a one-shot codex run can
> reproduce it for any new tx.

Treat this document as **mandatory** whenever the PoC/Replay stage produces
anything that must run code (not just narrate). If only prose is produced,
the replay result is at best `partially_reproduced`.

---

## Goal

Answer, with runnable evidence:

1. **Can we reconstruct the attacker's on-chain call sequence in Solidity?**
2. **Can we execute that sequence against the exact tx-prestate?**
3. **Do the on-fork outputs match the real attack to the wei?**
4. **What are the known blockers, encoded as tests (not footnotes)?**

---

## Repository Layout (mandatory for reproducibility)

```
foundry.toml
replay/
├── src/
│   ├── Tx<short>Interfaces.sol
│   └── Tx<short>Attack.sol
├── test/
│   └── Tx<short>Replay.t.sol
├── cache/
├── out/
└── anvil-cache/<tx-short>/    # optional; used by anvil --cache-path
```

- `<short>` = first 6 hex chars of the tx hash. Lowercase.
- One tx = one `Tx<short>*` file family. Do not merge multiple tx cases into
  one file. Do not put replay code under `scripts/` or `src/`.
- `foundry.toml` must pin `src`, `test`, `script`, `out`, `cache_path` to
  the `replay/` tree so the existing Python pipeline is unaffected.
- Add `/replay/out/` and `/replay/cache/` to `.gitignore`.

**Minimal `foundry.toml`**:

```toml
[profile.default]
src = "replay/src"
test = "replay/test"
script = "replay/script"
out = "replay/out"
cache_path = "replay/cache"
solc_version = "0.8.24"
evm_version = "cancun"
optimizer = true
optimizer_runs = 200

[rpc_endpoints]
bsc = "${BSC_RPC_URL}"
```

Change `evm_version` only if the target chain/block predates Cancun. Use
`shanghai` for pre-Cancun blocks and `london` only if you see an opcode
compatibility failure.

---

## Anvil: Pin the Local Node to the Exact Tx Prestate

The typical remote approach `vm.createSelectFork("bsc", ATTACK_TX_HASH)`
can fail with:

```
backend: failed committing transaction; transaction validation error:
authorization list not supported
```

This is an RPC backend compatibility issue, **not** a Foundry bug.

**Workaround: run anvil locally with `--fork-transaction-hash` and point
Foundry at it.** Anvil replays the entire block locally up to **but not
including** the target tx, leaving the local chain at the exact pre-state.

Recommended startup:

```bash
anvil \
  --fork-url "$RPC_URL" \
  --fork-transaction-hash <TX_HASH> \
  --port 8546 \
  --timeout 120000 \
  --retries 20 \
  --fork-retry-backoff 1000 \
  --no-rate-limit
```

Why each flag matters:

- `--fork-transaction-hash` pins the local chain to the prestate of that tx.
- `--timeout 120000` avoids upstream 30 s timeouts during Foundry's batched
  storage fetches.
- `--retries 20 --fork-retry-backoff 1000` survives transient upstream
  503/timeout spikes without aborting the fork.
- `--no-rate-limit` prevents Alchemy CUPS throttling from dropping
  mid-test storage reads. Symptom when missing: `connection closed before
  message completed` in the middle of `forge test`.
- Optional `--cache-path replay/anvil-cache/<tx-short>` speeds up repeated
  runs but is not required for correctness.

**Sanity check before running tests**:

```bash
cast chain-id --rpc-url http://127.0.0.1:8546
cast block-number --rpc-url http://127.0.0.1:8546         # must equal ATTACK_BLOCK - 1 or similar
cast tx --rpc-url http://127.0.0.1:8546 <TX_HASH>         # must return the target tx
```

---

## `.t.sol` Structure (mandatory test matrix)

Every attack tx under replay must produce a test file with **at minimum**
the five roles below. Tests that simply `PASS` without documenting a
blocker are insufficient; a blocker must be encoded, not narrated.

| # | Test name template | Fork source | Role |
|---|--------------------|-------------|------|
| 1 | `testReplay…FromParentBlockForkShowsSameBlockBlocker` | `vm.createSelectFork("<net>", BLOCK-1)` | Documents that parent-block state is insufficient (tokens inactive, accumulators unaligned, etc.). Must `vm.expectRevert()`. |
| 2 | `testReplay…FromAttackBlockEndStateShowsMutatedStateBlocker` | `vm.createSelectFork("<net>", BLOCK)` | Documents that end-of-block state cannot re-attack the same primitive. Must `vm.expectRevert()`. |
| 3 | `testSimulateCoreExploitOn<SomeAnchor>` | any accessible fork + `vm.deal` / direct funding | Fallback: exercises the exploit primitive without the exact prestate (bypasses flash callbacks if needed). Useful when exact prestate is unavailable. |
| 4 | `testReplay…FromExactTxPrestate` | local anvil at `127.0.0.1:8546` + `vm.roll(ATTACK_BLOCK)` | The authoritative replay. Asserts exact on-chain deltas. |
| 5 | `testRiskUpperBoundAtTxPrestate` | local anvil at `127.0.0.1:8546` + `vm.roll(ATTACK_BLOCK)` | Read-only defensive evaluation. See `ATTACK_TX_ANALYSIS_RISK_BOUND.md`. |

Naming is case-insensitive but the **semantics are not optional**. If any
role does not apply, write it with a short comment explaining why and keep
the test file self-documenting.

### Minimal `Vm` interface stub

```solidity
interface Vm {
    function createSelectFork(string calldata urlOrAlias) external returns (uint256);
    function createSelectFork(string calldata urlOrAlias, uint256 blockNumber) external returns (uint256);
    function createSelectFork(string calldata urlOrAlias, bytes32 txHash) external returns (uint256);
    function rollFork(bytes32 txHash) external;
    function expectRevert() external;
    function deal(address who, uint256 newBalance) external;
    function roll(uint256 newHeight) external;
}

Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
```

Do not import `forge-std`. Staying interface-only removes a remapping
requirement and keeps the harness portable.

---

## Attacker-Contract Solidity Reconstruction

`replay/src/Tx<short>Attack.sol` must express the attacker's on-chain
behavior, not a generic exploit sketch. Minimum requirements:

1. Separate **addresses/constants** into a small `Tx<short>ReplayAddresses`
   base contract so tests can reference them without hardcoding duplicates.
2. Express the main attacker contract as a **Launcher + Worker** pair when
   the real attack uses a helper worker (common pattern: CREATE2 helper +
   flash callback). This matches the trace structure (`eb21…` outer +
   `00d6…` worker in the reference case) and avoids fighting
   `msg.sender` checks.
3. Expose both:
   - `attack()` — the real entrypoint driven by a flash swap.
   - `simulateWithoutFlash(uint256 seed) payable` — a bypass entrypoint
     that lets the fallback test (#3) skip the flash callback.
4. Every hardcoded address must be **checksummed**. Solidity 0.8.x will
   reject unchecksummed literals.

### Flash callback conventions

- Implement the exact callback name the pair expects
  (`pancakeCall(address,uint256,uint256,bytes)` for PancakeSwap v2).
- Guard with `require(msg.sender == <flashPair>)`.
- Repay the exact `FLASH_REPAY_AMOUNT` observed in the trace, not a
  recomputed value. Chains sometimes have nonstandard fees.

---

## Deterministic Assertions (hard-coded expected values)

The point of the exact replay test is not "something happened". It is
"the exact same thing happened". Encode expected on-fork outputs as
contract constants and assert equality (not `>` / `<`).

Minimum set of hard-coded values:

- `EXPECTED_<SETTLEMENT_OBJECT>_DELTA` — the main on-chain write the
  attack produces (e.g. `vault slisBNB` transferred out).
- `EXPECTED_PROFIT_<TOKEN>` — net profit retained in the launcher after
  all repayments.
- `PRESTATE_*` — the on-chain values you read from the prestate fork
  (balances, accumulators) that your risk bound depends on.

Obtain these values by first running the test with loose `require(... >
0, ...)` inequalities, reading the `emit log_named_*` output, then
replacing them with exact equality checks. A regression later — chain
reorg, upstream trace change, accidental code tweak — will fail loudly.

### Event declarations for `-vv` logging

```solidity
event log_named_uint(string key, uint256 val);
event log_named_decimal_uint(string key, uint256 val, uint256 decimals);
```

These match Forge's built-in printer and avoid pulling in `forge-std`.

---

## Known Pitfalls (each should become a test, not a note)

1. **Unverified SKYAI-like tokens `NotActivated` at `block-1`**. Some tokens
   bundle selectors that only become callable after specific state is set
   up. A naive parent-block fork silently fails at the first transfer.
2. **Attack block end-state is unusable for re-attack**. Writes have
   already been applied (`totalClaimed`, `magnifiedDividendPerShare`), so
   the attacker's economic premise no longer holds.
3. **Remote `vm.createSelectFork(txHash)` breaks on BSC/Alchemy** with
   `authorization list not supported`. Always use local anvil with
   `--fork-transaction-hash`.
4. **Foundry drops connections mid-run under default anvil flags**. Always
   pass `--timeout 120000 --retries 20 --no-rate-limit` to anvil.
5. **Port collisions**. The pid you see from the shell is the shell
   wrapper, not anvil. Always check with `lsof -nP -iTCP:8546 -sTCP:LISTEN`
   before launching a new instance.
6. **Unchecksummed addresses** break compilation on 0.8.x. Use
   `cast --to-checksum-address <addr>` when in doubt.

---

## End-to-End Runbook for a New Tx

Plug the tx-specific placeholders in and run:

```bash
# 1. Sanity: artifacts + result.md already exist
ls transactions/<TX>/analysis/result.md

# 2. foundry.toml already present? Otherwise create it (see template above)
test -f foundry.toml

# 3. Generate Tx<short>Interfaces.sol and Tx<short>Attack.sol under replay/src/
#    Base them on the trace (`trace/*.json`) and decompiled attacker contracts
#    (`contract_sources/<attacker>/decompiled/optimized.sol`).

# 4. Generate Tx<short>Replay.t.sol under replay/test/ with the 5 tests above.
#    Start with `require(... > 0, ...)` inequalities.

# 5. Start the local prestate node
anvil \
  --fork-url "$RPC_URL" \
  --fork-transaction-hash <TX_HASH> \
  --port 8546 \
  --timeout 120000 --retries 20 --fork-retry-backoff 1000 --no-rate-limit &

# 6. Smoke-run tests, capture log_named_* values
forge test -vv

# 7. Promote observed values to EXPECTED_* / PRESTATE_* constants and
#    tighten every `require` to `==`. Rerun `forge test -vv` — must stay green.

# 8. Append replay + risk bound results into transactions/<TX>/analysis/result.md
#    following ATTACK_TX_ANALYSIS_POC_REPLAY.md and ATTACK_TX_ANALYSIS_RISK_BOUND.md.
```

---

## Definition of Done

The fork harness is considered complete for this tx only when **all** of
the following are true:

- `forge test -vv` passes every test in the 5-role matrix.
- The exact-prestate test uses `==` assertions on every expected value.
- Blocker tests encode their reverts via `vm.expectRevert()` (they must
  not be skipped, commented out, or `try/catch`-ed away).
- The risk upper bound test reads its inputs directly from the fork and
  uses `==` against `PRESTATE_*` constants.
- `transactions/<TX>/analysis/result.md` has been updated under the
  `RPC Replay at Attack Block` and `Risk Upper Bound` sections, including
  the `forge test` command and the on-fork numbers.

Anything less should be reported as `partially_reproduced` or `blocked`
per `ATTACK_TX_ANALYSIS_POC_REPLAY.md §6`.
