基于反编译的代码分析，我将这个合约重构为一个清晰、专业的代币众筹/投资管理合约。以下是优化后的代码：

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TokenVestingCrowdsale
 * @dev 代币众筹和投资管理合约
 * @notice 支持代币销售、节点管理、黑名单功能和收益分配
 * @custom:security-contact security@example.com
 */
contract TokenVestingCrowdsale is Initializable, OwnableUpgradeable {
    
    // ============ Constants ============
    uint256 private constant DECIMAL_MULTIPLIER = 1e18;
    uint256 private constant PHASE_DURATION = 300; // 5分钟 (300秒)
    uint256 private constant EXTENDED_PHASE_DURATION = 900; // 15分钟 (900秒)
    
    // ============ State Variables ============
    
    // Token and pricing configuration
    IERC20 public usdtToken;                    // USDT代币合约地址
    uint256 public buyRate;                     // 购买汇率
    uint256 public sellRate;                    // 出售汇率
    uint256 public returnRate;                  // 回报率
    uint256 public nodeRate;                    // 节点奖励率
    
    // Investment limits and timing
    uint256 public minBNBAmount;                // 最小BNB投资金额
    uint256 public maxBNBAmount;                // 最大BNB投资金额  
    uint256 public startTime;                   // 众筹开始时间
    uint256 public nodeAmount;                  // 节点总投资金额
    
    // Fee and reward configuration
    uint256 public marketingFeeRate;            // 营销费率
    uint256 public partnerFeeAmount;            // 合作伙伴费用金额
    uint256 public nodeFeeAmount;               // 节点费用金额
    uint256 public tokenMultiplier;             // 代币倍数
    uint256 public stakingRewardRate;           // 质押奖励率
    uint256 public platformFeeRate;             // 平台费率
    uint256 public referralRewardRate;          // 推荐奖励率
    uint256 public liquidityRate;               // 流动性率
    
    // Contract addresses for external interactions
    address public marketingWallet;             // 营销钱包地址
    address public defaultReferrer;             // 默认推荐人地址
    address public blacklistManager;            // 黑名单管理员
    address public partnerContract;             // 合作伙伴合约
    address public nodeContract;                // 节点合约
    address public feeCollector;                // 费用收集者
    address public stakingContract;             // 质押合约
    address public emergencyManager;            // 紧急管理员
    address public superAdmin;                  // 超级管理员
    address public buybackManager;              // 回购管理员
    address public liquidityManager;            // 流动性管理员
    
    // Investment tracking
    uint256 public totalInvestmentPool;         // 总投资池
    uint256 public currentRewardMultiplier;     // 当前奖励倍数
    uint256 public totalUserCount;              // 总用户数
    
    // User data structures
    struct UserInfo {
        uint256 investmentAmount;               // 投资金额
        uint256 lastClaimTime;                  // 上次领取时间
        uint256 totalEarned;                    // 总收益
        bool isActive;                          // 是否激活
        bool isBlacklisted;                     // 是否被加入黑名单
        address referrer;                       // 推荐人
    }
    
    struct NodeInfo {
        uint256 nodeInvestment;                 // 节点投资
        uint256 lastUpdateTime;                 // 上次更新时间
        bool isNode;                            // 是否为节点
    }
    
    // Mappings for user data
    mapping(address => UserInfo) public userInvestments;
    mapping(address => NodeInfo) public nodeInvestments;
    mapping(address => bool) public hasPurchased;
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public isWhitelisted;
    mapping(uint256 => address) public userByIndex;
    
    // ============ Events ============
    event InvestmentMade(address indexed user, uint256 amount, address indexed referrer);
    event RewardsClaimed(address indexed user, uint256 amount);
    event NodeCreated(address indexed user, uint256 amount);
    event BlacklistUpdated(address indexed user, bool isBlacklisted);
    event ConfigurationUpdated(string parameter, uint256 newValue);
    event EmergencyWithdraw(address indexed token, uint256 amount);
    event ReferralRewardPaid(address indexed referrer, address indexed referee, uint256 amount);
    
    // ============ Errors ============
    error InvestmentTooSmall(uint256 provided, uint256 minimum);
    error InvestmentTooLarge(uint256 provided, uint256 maximum);
    error SaleNotStarted(uint256 currentTime, uint256 startTime);
    error UserBlacklisted(address user);
    error AlreadyPurchased(address user);
    error InvalidPhase(uint256 currentTime, uint256 startTime);
    error InsufficientContractBalance(uint256 requested, uint256 available);
    error InvalidAddress(address provided);
    error UnauthorizedAccess(address caller, address required);
    
    // ============ Modifiers ============
    modifier onlyActiveUser(address user) {
        require(userInvestments[user].isActive, "User not active");
        _;
    }
    
    modifier notBlacklisted(address user) {
        if (isBlacklisted[user]) revert UserBlacklisted(user);
        _;
    }
    
    modifier onlyAuthorized() {
        require(
            msg.sender == owner() || 
            msg.sender == blacklistManager || 
            msg.sender == superAdmin,
            "Not authorized"
        );
        _;
    }
    
    modifier validAddress(address addr) {
        if (addr == address(0)) revert InvalidAddress(addr);
        _;
    }
    
    // ============ Initialization ============
    
    /**
     * @dev 初始化合约
     * @notice 只能调用一次，设置基本参数
     */
    function initialize() external initializer {
        __Ownable_init();
        
        // 设置默认参数
        buyRate = 1000;                     // 默认购买率
        sellRate = 900;                     // 默认出售率  
        returnRate = 120;                   // 默认回报率 120%
        nodeRate = 150;                     // 默认节点率 150%
        minBNBAmount = 0.01 ether;          // 最小投资 0.01 BNB
        maxBNBAmount = 10 ether;            // 最大投资 10 BNB
        currentRewardMultiplier = DECIMAL_MULTIPLIER;
    }
    
    // ============ Investment Functions ============
    
    /**
     * @dev 用户投资函数
     * @param referrer 推荐人地址
     * @notice 用户可以通过发送BNB进行投资
     */
    function invest(address referrer) external payable notBlacklisted(msg.sender) {
        uint256 investmentAmount = msg.value;
        
        // 验证投资金额
        if (investmentAmount < minBNBAmount) {
            revert InvestmentTooSmall(investmentAmount, minBNBAmount);
        }
        if (investmentAmount > maxBNBAmount) {
            revert InvestmentTooLarge(investmentAmount, maxBNBAmount);
        }
        
        // 验证销售时间和阶段
        _validateSalePhase();
        
        // 验证用户状态
        require(!hasPurchased[msg.sender], "Already purchased");
        require(msg.sender == tx.origin, "Must be EOA");
        
        // 验证推荐人
        if (referrer == address(0)) {
            referrer = defaultReferrer;
        }
        
        // 记录用户投资
        UserInfo storage user = userInvestments[msg.sender];
        user.investmentAmount = investmentAmount;
        user.lastClaimTime = block.timestamp;
        user.isActive = true;
        user.referrer = referrer;
        
        hasPurchased[msg.sender] = true;
        userByIndex[totalUserCount] = msg.sender;
        totalUserCount++;
        
        // 更新总投资池
        totalInvestmentPool += investmentAmount;
        
        // 分发推荐奖励
        _processReferralReward(referrer, investmentAmount);
        
        emit InvestmentMade(msg.sender, investmentAmount, referrer);
    }
    
    /**
     * @dev 验证销售阶段
     * @notice 检查当前时间是否在有效的销售阶段内
     */
    function _validateSalePhase() internal view {
        if (block.timestamp < startTime) {
            revert SaleNotStarted(block.timestamp, startTime);
        }
        
        uint256 phaseEndTime = startTime + PHASE_DURATION;
        uint256 extendedEndTime = startTime + EXTENDED_PHASE_DURATION;
        
        // 检查是否在有效阶段内
        require(
            block.timestamp <= extendedEndTime,
            "Sale phase ended"
        );
        
        // 特殊阶段验证逻辑
        if (block.timestamp > phaseEndTime && block.timestamp <= extendedEndTime) {
            // 扩展阶段的特殊验证
            _validateExtendedPhase();
        }
    }
    
    /**
     * @dev 验证扩展阶段
     * @notice 在扩展销售阶段进行额外验证
     */
    function _validateExtendedPhase() internal view {
        // 扩展阶段可能需要特殊的验证逻辑
        // 例如：检查特定条件、限制投资金额等
        require(totalInvestmentPool > 0, "No investments in extended phase");
    }
    
    /**
     * @dev 处理推荐奖励
     * @param referrer 推荐人地址
     * @param investmentAmount 投资金额
     */
    function _processReferralReward(address referrer, uint256 investmentAmount) internal {
        if (referrer != address(0) && referrer != msg.sender) {
            uint256 referralReward = (investmentAmount * referralRewardRate) / 10000;
            
            // 发送推荐奖励
            if (address(this).balance >= referralReward) {
                payable(referrer).transfer(referralReward);
                emit ReferralRewardPaid(referrer, msg.sender, referralReward);
            }
        }
    }
    
    // ============ Reward and Claiming Functions ============
    
    /**
     * @dev 计算用户可领取的收益
     * @param user 用户地址
     * @return 可领取的收益金额
     */
    function calculateEarnings(address user) external view returns (uint256) {
        UserInfo memory userInfo = userInvestments[user];
        
        if (!userInfo.isActive || userInfo.investmentAmount == 0) {
            return 0;
        }
        
        uint256 timePassed = block.timestamp - userInfo.lastClaimTime;
        uint256 baseReward = (userInfo.investmentAmount * timePassed * currentRewardMultiplier) / DECIMAL_MULTIPLIER;
        
        return baseReward;
    }
    
    /**
     * @dev 用户领取收益
     * @notice 用户可以领取基于时间的收益
     */
    function claimRewards() external onlyActiveUser(msg.sender) notBlacklisted(msg.sender) {
        uint256 earnings = this.calculateEarnings(msg.sender);
        require(earnings > 0, "No earnings to claim");
        
        UserInfo storage user = userInvestments[msg.sender];
        user.lastClaimTime = block.timestamp;
        user.totalEarned += earnings;
        
        // 发送收益
        require(address(this).balance >= earnings, "Insufficient contract balance");
        payable(msg.sender).transfer(earnings);
        
        emit RewardsClaimed(msg.sender, earnings);
    }
    
    // ============ Node Management Functions ============
    
    /**
     * @dev 创建节点投资
     * @param user 节点用户地址
     * @notice 只有授权用户可以创建节点
     */
    function createNode(address user) external onlyAuthorized validAddress(user) {
        NodeInfo storage nodeInfo = nodeInvestments[user];
        UserInfo storage userInfo = userInvestments[user];
        
        require(userInfo.isActive, "User must be active investor");
        require(!nodeInfo.isNode, "Already a node");
        
        nodeInfo.isNode = true;
        nodeInfo.nodeInvestment = userInfo.investmentAmount;
        nodeInfo.lastUpdateTime = block.timestamp;
        
        nodeAmount += userInfo.investmentAmount;
        
        emit NodeCreated(user, userInfo.investmentAmount);
    }
    
    /**
     * @dev 移除节点
     * @param user 节点用户地址
     */
    function removeNode(address user) external onlyAuthorized {
        NodeInfo storage nodeInfo = nodeInvestments[user];
        require(nodeInfo.isNode, "Not a node");
        
        nodeAmount -= nodeInfo.nodeInvestment;
        
        nodeInfo.isNode = false;
        nodeInfo.nodeInvestment = 0;
        nodeInfo.lastUpdateTime = block.timestamp;
    }
    
    // ============ Blacklist Management ============
    
    /**
     * @dev 添加用户到黑名单
     * @param user 用户地址
     */
    function addToBlacklist(address user) external onlyAuthorized validAddress(user) {
        isBlacklisted[user] = true;
        userInvestments[user].isBlacklisted = true;
        
        emit BlacklistUpdated(user, true);
    }
    
    /**
     * @dev 从黑名单移除用户
     * @param user 用户地址
     */
    function removeFromBlacklist(address user) external onlyAuthorized validAddress(user) {
        isBlacklisted[user] = false;
        userInvestments[user].isBlacklisted = false;
        
        emit BlacklistUpdated(user, false);
    }
    
    // ============ Admin Configuration Functions ============
    
    /**
     * @dev 设置USDT代币地