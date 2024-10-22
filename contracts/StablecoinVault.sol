// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "node_modules/@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "node_modules/@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title StablecoinVault
 * @dev A vault contract for managing USDC and USDT deposits with time-weighted voting power
 * @notice This contract allows users to deposit stablecoins and receive voting power based on their deposit amount and duration
 */
contract StablecoinVault is ReentrancyGuard {
    // Token interfaces
    IERC20 public immutable usdcToken;
    IERC20 public immutable usdtToken;

    // User balances and state
    mapping(address => uint256) public usdcBalances;
    mapping(address => uint256) public usdtBalances;
    mapping(address => uint256) public lastDepositTime;
    mapping(address => bool) public isLocked;

    // Time constants
    uint256 public constant COOLDOWN_PERIOD = 1 days;
    uint256 public constant WEIGHT_PERIOD = 30 days;

    // Configuration
    uint256 public minDepositAmount;
    uint256 public maxDepositAmount;
    uint256 public votingPowerCap;

    event Deposit(address indexed user, uint256 amount, bool isUSDC);
    event Withdraw(address indexed user, uint256 amount, bool isUSDC);
    event Lock(address indexed user, bool locked);

    /**
     * @dev Contract constructor
     * @param _usdcToken Address of the USDC token contract
     * @param _usdtToken Address of the USDT token contract
     * @param _minDepositAmount Minimum amount that can be deposited
     * @param _maxDepositAmount Maximum amount that can be deposited
     * @param _votingPowerCap Maximum voting power per address
     */
    constructor(address _usdcToken, address _usdtToken, uint256 _minDepositAmount, uint256 _maxDepositAmount, uint256 _votingPowerCap) {
        require(_usdcToken != address(0), "Invalid USDC Token");
        require(_usdtToken != address(0), "Invalid USDT Token");
        usdcToken = IERC20(_usdcToken);
        usdtToken = IERC20(_usdtToken);
        minDepositAmount = _minDepositAmount;
        maxDepositAmount = _maxDepositAmount;
        votingPowerCap = _votingPowerCap;
    }

    /**
     * @dev Deposits stablecoins into the vault
     * @param _amount Amount to deposit
     * @param _isUSDC True if depositing USDC, false for USDT
     */
    function deposit(uint256 _amount, bool _isUSDC) external nonReentrant {
        require(_amount > 0, "Deposit should be larger than 0");
        require(_amount >= minDepositAmount, "Amount below minimum deposit");
        require(_amount <= maxDepositAmount, "Amount above maximum deposit");

        IERC20 token = _isUSDC ? usdcToken : usdtToken;
        mapping(address => uint256) storage balances = _isUSDC ? usdcBalances : usdtBalances;

        uint256 newBalance = balances[msg.sender] + _amount;
        require(newBalance <= maxDepositAmount, "Total deposit exceeds maximum");

        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        balances[msg.sender] = newBalance;
        lastDepositTime[msg.sender] = block.timestamp;

        emit Deposit(msg.sender, _amount, _isUSDC);

    }

    function withdraw(uint256 _amount, bool _isUSDC) external nonReentrant  {
        require(_amount > 0, "Withdrawal must be greater than 0");
        require(!isLocked[msg.sender], "Account is locked for voting!");
        require(block.timestamp >= lastDepositTime[msg.sender] + COOLDOWN_PERIOD, "Cooldown period is not over.");

        if (_isUSDC) {
            require(usdcBalances[msg.sender] >= _amount, "No USDC sufficient balance to withdraw");
            usdcBalances[msg.sender] -= _amount;
            require(usdcToken.transfer(msg.sender, _amount), "USDC transfer has failed!");
        } else {
            require(usdtBalances[msg.sender] >= _amount, "No USDT sufficient balance to withdraw");
            usdtBalances[msg.sender] -= _amount;
            require(usdtToken.transfer(msg.sender, _amount), "USDT transfer has failed!");
        }

        emit Withdraw(msg.sender, _amount, _isUSDC);
    }

    function getVotingPower(address _user) public view returns(uint256) {
        uint256 totalBalance = usdcBalances[_user] + usdtBalances[_user];
        uint256 timeWeight = (block.timestamp - lastDepositTime[_user]) / 1 days;
        if (timeWeight > WEIGHT_PERIOD) {
            timeWeight = WEIGHT_PERIOD;
        } 
        return totalBalance * (WEIGHT_PERIOD + timeWeight) / WEIGHT_PERIOD;
    }

    
}