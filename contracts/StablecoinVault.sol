// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "node_modules/@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "node_modules/@openzeppelin/contracts/utils/Pausable.sol";
import "node_modules/@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title StablecoinVault
 * @dev A vault contract for managing USDC and USDT deposits with time-weighted voting power
 * @notice This contract allows users to deposit stablecoins and receive voting power based on their deposit amount and duration
 */
contract StablecoinVault is ReentrancyGuard, Pausable, Ownable {
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
    event MinDepositAmountUpdated(uint256 newAmount);
    event MaxDepositAmountUpdated(uint256 newAmount);
    event VotingPowerCapUpdated(uint256 newCap);

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
    function deposit(uint256 _amount, bool _isUSDC) external nonReentrant whenNotPaused {
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
    /**
     * @dev Withdraws stablecoins from the vault
     * @param _amount Amount to withdraw
     * @param _isUSDC True if withdrawing USDC, false for USDT
     */
    function withdraw(uint256 _amount, bool _isUSDC) external nonReentrant whenNotPaused  {
        require(!isLocked[msg.sender], "Account is locked for voting!");
        require(block.timestamp >= lastDepositTime[msg.sender] + COOLDOWN_PERIOD, "Cooldown period is not over.");

        IERC20 token = _isUSDC ? usdcToken : usdtToken;
        mapping(address => uint256) storage balances = _isUSDC ? usdcBalances : usdtBalances;

        require(balances[msg.sender] >= _amount, "Insufficent balance");
        balances[msg.sender] -= amount;
        require(token.transfer(msg.sender, _amount), "Transfer failed");

        emit Withdraw(msg.sender, _amount, _isUSDC);
    }

    /**
     * @dev Calculates the voting power of an address
     * @param _user Address to calculate voting power for
     * @return Voting power amount
     */
    function getVotingPower(address _user) public view returns(uint256) {
        uint256 totalBalance = usdcBalances[_user] + usdtBalances[_user];
        if (totalBalance == 0) {return 0;}

        uint256 timeWeight = (block.timestamp - lastDepositTime[_user]) / 1 days;
        timeWeight = timeWeight > WEIGHT_PERIOD ? WEIGHT_PERIOD : timeWeight;

        uint256 votingPower = totalBalance * (WEIGHT_PERIOD + timeWeight) / WEIGHT_PERIOD;
        return votingPower > votingPowerCap ? votingPowerCap : votingPower;
    }

    /**
     * @dev Returns the total balance of a user (USDC + USDT)
     * @param _user Address to check balance for
     * @return Total balance in smallest units
     */
    function getTotalBalance(address _user) external view returns(uint256) {
        return usdcBalances[_user] + usdtBalances[_user];
    }

    /**
     * @dev Locks an account for voting
     * @param _user Address to lock
     */
    function lockAccount(address _user) external {
        // TO DO: Add access control - only voting contract should call this
        isLocked[msg.sender] = true;
        emit Lock(_user, true);
    }

    /**
     * @dev Unlocks an account after voting
     * @param _user Address to unlock
     */
    function unlockAccount(address _user) external {
        isLocked[msg.sender] = false;
        emit Lock(_user, false);
    }

    /**
     * @dev Updates the minimum deposit amount
     * @param _newAmount New minimum deposit amount
     */
    function setMinDepositAmout(uint256 _newAmount) external onlyOwner {
        require(_newAmount < maxDepositAmount, "Min cannot exceed max");
        minDepositAmount = _newAmount;
        emit MinDepositAmountUpdated(_newAmount);
    }
    /**
     * @dev Updates the maximum deposit amount
     * @param _newAmount New maximum deposit amount
     */
    function setMaxDepositAmount(uint256 _newAmount) external onlyOwner {
        require(_newAmount > minDepositAmount, "Max cannot be below min");
        maxDepositAmount = _newAmount;
        emit MaxDepositAmountUpdated(_newAmount);
    }

    /**
     * @dev Pauses all deposit and withdraw operations
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all deposit and withdraw operations
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
}