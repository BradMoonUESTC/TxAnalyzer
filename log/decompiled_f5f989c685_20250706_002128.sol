基于反编译代码的分析，这是一个具有复杂流动性池管理和推荐机制的DeFi合约。以下是优化重构后的代码：

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
    function transfer(address to, uint256 value) external returns (bool);
}

/**
 * @title LiquidityMiningPool
 * @notice 具有推荐机制的流动性挖矿合约
 * @dev 支持BNB投资、推荐奖励、流动性管理等功能
 */
contract LiquidityMiningPool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;

    // ============ 状态变量 ============
    
    // 基础配置
    uint256 public buyRate;                    // 购买费率 (基点，10000 = 100%)
    uint256 public minBNBAmount;               // 最小BNB投资金额
    uint256 public maxBNBAmount;               // 最大BNB投资金额
    uint256 public currentIndex;               // 当前用户索引
    uint256 public getTimes;                   // 获取时间戳
    uint256 public totalPoolValue;             // 总池价值
    uint256 public totalTokenSupply;           // 总代币供应量
    uint256 public timeInterval;               // 时间间隔
    uint256 public totalBNBCollected;          // 总收集的BNB数量
    uint256 public averageUpdateRate;          // 平均更新率
    
    // 地址配置
    address public parAddress;                 // 配对地址(代币地址)
    address public defaultAddress;             // 默认地址
    address public topAddress;                 // 顶级地址
    address public projectAddress;             // 项目地址
    address public ownerB;                     // 备用owner
    address public liquidityManager;           // 流动性管理员
    address public treasuryWallet;             // 资金管理员
    
    // Uniswap相关
    IUniswapV2Router public uniswapRouter;
    
    // 初始化状态
    bytes32 private initializationState;
    
    // ============ 用户数据结构 ============
    
    struct UserInfo {
        uint256 investment;                    // 用户投资金额
        uint256 joinTime;                     // 加入时间
        uint256 earnedAmount;                 // 已赚取金额
        uint256 lpTokenAmount;                // LP代币数量
        uint256 userIndex;                    // 用户索引
        address referrer;                     // 推荐人
        bool isBlacklisted;                   // 是否被拉黑
        bool hasLPTokens;                     // 是否有LP代币
    }
    
    // ============ 存储映射 ============
    
    mapping(address => UserInfo) public userInfo;           // 用户信息
    mapping(uint256 => address) public indexToUser;         // 索引到用户地址
    mapping(address => bool) public isRegistered;           // 是否已注册
    mapping(address => uint256) public userTokenBalance;    // 用户代币余额
    mapping(address => bool) public authorizedCallers;      // 授权调用者
    
    // ============ 事件定义 ============
    
    event BindIntro(address indexed referrer, address indexed user, uint256 timestamp);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Investment(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawal(address indexed user, uint256 amount, uint256 timestamp);
    event LiquidityRemoved(address indexed user, uint256 lpAmount, uint256 bnbAmount);
    event RewardClaimed(address indexed user, uint256 amount);
    event ParameterUpdated(string parameter, uint256 oldValue, uint256 newValue);
    
    // ============ 错误定义 ============
    
    error Unauthorized();
    error InvalidAmount();
    error UserBlacklisted();
    error InsufficientBalance();
    error TransferFailed();
    error AlreadyInitialized();
    error NotInitialized();
    error InvalidAddress();
    error ExceedsMaximum();
    error BelowMinimum();
    
    // ============ 修饰符 ============
    
    modifier onlyAuthorized() {
        if (msg.sender != owner() && !authorizedCallers[msg.sender]) {
            revert Unauthorized();
        }
        _;
    }
    
    modifier notBlacklisted(address user) {
        if (userInfo[user].isBlacklisted) {
            revert UserBlacklisted();
        }
        _;
    }
    
    modifier validAddress(address addr) {
        if (addr == address(0)) {
            revert InvalidAddress();
        }
        _;
    }
    
    // ============ 构造函数和初始化 ============
    
    constructor() {
        // 构造函数保持简单，主要逻辑在initialize中
    }
    
    /**
     * @notice 初始化合约
     * @dev 只能调用一次
     */
    function initialize() external payable {
        if (bytes1(initializationState) == 0x01) {
            revert AlreadyInitialized();
        }
        
        initializationState = 0x01;
        
        // 设置默认值
        buyRate = 500; // 5%
        minBNBAmount = 0.01 ether;
        maxBNBAmount = 10 ether;
        timeInterval = 86400; // 24小时
        currentIndex = 1;
        
        _transferOwnership(msg.sender);
    }
    
    // ============ 核心业务函数 ============
    
    /**
     * @notice 用户投资BNB
     * @param user 投资用户地址
     */
    function investBNB(address user) 
        external 
        payable 
        nonReentrant 
        notBlacklisted(user)
        validAddress(user)
    {
        if (msg.value < minBNBAmount) {
            revert BelowMinimum();
        }
        
        if (msg.value > maxBNBAmount) {
            revert ExceedsMaximum();
        }
        
        if (msg.sender != user && msg.sender != owner()) {
            revert Unauthorized();
        }
        
        UserInfo storage userData = userInfo[user];
        
        // 首次投资时注册用户
        if (!isRegistered[user]) {
            _registerUser(user);
        }
        
        // 更新投资金额
        userData.investment += msg.value;
        userData.joinTime = block.timestamp;
        
        // 更新总收集金额
        totalBNBCollected += msg.value;
        
        emit Investment(user, msg.value, block.timestamp);
    }
    
    /**
     * @notice 绑定推荐关系
     * @param user 用户地址
     * @param referrer 推荐人地址
     */
    function bindReferrer(address user, address referrer) 
        external 
        onlyAuthorized 
        validAddress(user) 
        validAddress(referrer)
    {
        if (user == referrer) {
            revert InvalidAddress();
        }
        
        if (userInfo[user].referrer != address(0)) {
            return; // 已有推荐人
        }
        
        userInfo[user].referrer = referrer;
        
        emit BindIntro(referrer, user, block.timestamp);
    }
    
    /**
     * @notice 计算用户可提取的收益
     * @param user 用户地址
     * @return 可提取的收益数量
     */
    function calculateEarnings(address user) public view returns (uint256) {
        UserInfo memory userData = userInfo[user];
        
        if (userData.isBlacklisted || userData.investment == 0) {
            return 0;
        }
        
        // 计算基于时间和投资额的收益
        uint256 timePassed = block.timestamp - userData.joinTime;
        uint256 timeUnits = timePassed / timeInterval;
        
        if (timeUnits == 0) {
            return 0;
        }
        
        // 基础收益 = 投资额 * 时间单位 * 费率 / 10000
        uint256 baseEarnings = (userData.investment * timeUnits * buyRate) / 10000;
        
        return baseEarnings + userData.earnedAmount;
    }
    
    /**
     * @notice 用户提取收益
     * @param user 用户地址
     */
    function claimRewards(address user) 
        external 
        nonReentrant 
        notBlacklisted(user) 
        returns (uint256)
    {
        if (msg.sender != user && msg.sender != owner()) {
            revert Unauthorized();
        }
        
        uint256 earnings = calculateEarnings(user);
        if (earnings == 0) {
            revert InvalidAmount();
        }
        
        if (address(this).balance < earnings) {
            revert InsufficientBalance();
        }
        
        // 更新用户数据
        userInfo[user].earnedAmount = 0;
        userInfo[user].joinTime = block.timestamp;
        
        // 转账
        (bool success, ) = payable(user).call{value: earnings}("");
        if (!success) {
            revert TransferFailed();
        }
        
        emit RewardClaimed(user, earnings);
        return earnings;
    }
    
    /**
     * @notice 移除流动性
     * @param user 用户地址
     */
    function removeLiquidity(address user) 
        external 
        onlyAuthorized 
        nonReentrant 
        returns (uint256)
    {
        UserInfo storage userData = userInfo[user];
        
        if (!userData.hasLPTokens) {
            revert InvalidAmount();
        }
        
        if (tx.origin != user) {
            revert Unauthorized();
        }
        
        uint256 lpAmount = userData.lpTokenAmount;
        if (lpAmount == 0) {
            return 0;
        }
        
        // 通过Uniswap移除流动性
        address weth = uniswapRouter.WETH();
        
        // 批准路由器使用LP代币
        IERC20(parAddress).safeApprove(address(uniswapRouter), lpAmount);
        
        // 移除流动性
        (uint256 tokenAmount, uint256 ethAmount) = uniswapRouter.removeLiquidityETH(
            parAddress,
            lpAmount,
            0, // 接受任何数量的代币
            0, // 接受任何数量的ETH
            address(this),
            block.timestamp + 3600
        );
        
        // 提取WETH为ETH
        IWETH(weth).withdraw(ethAmount);
        
        // 转账给用户
        (bool success, ) = payable(user).call{value: ethAmount}("");
        if (!success) {
            revert TransferFailed();
        }
        
        // 更新用户数据
        userData.lpTokenAmount = 0;
        userData.hasLPTokens = false;
        
        // 如果用户没有其他资产，从索引中移除
        if (userData.investment == 0) {
            _unregisterUser(user);
        }
        
        emit LiquidityRemoved(user, lpAmount, ethAmount);
        return ethAmount;
    }
    
    // ============ 管理员函数 ============
    
    /**
     * @notice 设置购买费率
     * @param newRate 新费率 (基点)
     */
    function setBuyRate(uint256 newRate) external onlyOwner {
        emit ParameterUpdated("buyRate", buyRate, newRate);
        buyRate = newRate;
    }
    
    /**
     * @notice 设置最小和最大BNB投资金额
     * @param minAmount 最小金额
     * @param maxAmount 最大金额
     */
    function setInvestmentLimits(uint256 minAmount, uint256 maxAmount) external onlyOwner {
        if (minAmount >= maxAmount) {
            revert InvalidAmount();
        }
        
        minBNBAmount = minAmount;
        maxBNBAmount = maxAmount;
    }
    
    /**
     * @notice 设置Uniswap路由器地址
     * @param router 路由器地址
     */
    function setUniswapRouter(address router) external onlyOwner validAddress(router) {
        uniswapRouter = IUniswapV2Router(router);
    }
    
    /**
     * @notice 设置项目地址
     * @param projectAddr 项目地址
     */
    function setProjectAddress(address projectAddr) external onlyOwner validAddress(projectAddr) {
        projectAddress = projectAddr;
    }
    
    /**
     * @notice 设置配对地址
     * @param pairAddr 配对地址
     */
    function setPairAddress(address pairAddr) external onlyOwner validAddress(pairAddr) {
        parAddress = pairAddr;
    }
    
    /**
     * @notice 设置备用owner
     * @param newOwnerB 新的备用owner地址
     */
    function setOwnerB(address newOwnerB) external onlyOwner validAddress(newOwnerB) {
        ownerB = newOwnerB;
    }
    
    /**
     * @notice 设置流动性管理员
     * @param manager 管理员地址
     */
    function setLiquidityManager(address manager) external onlyOwner validAddress(manager) {
        liquidityManager = manager;
    }
    
    /**
     * @notice 设置资金管理员
     * @param treasury 资金管理员地址
     */
    function setTreasuryWallet(address treasury) external onlyOwner validAddress(treasury) {
        treasuryWallet = treasury;
    }
    
    /**
     * @notice 添加/移除授权调用者
     * @param caller