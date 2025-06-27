// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Decentralized Lending Platform
 * @dev A simple lending platform where users can deposit collateral and borrow tokens
 */
contract Project {
    
    // State variables
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public borrowedAmounts;
    mapping(address => uint256) public collateral;
    
    uint256 public totalDeposits;
    uint256 public totalBorrowed;
    uint256 public constant COLLATERAL_RATIO = 150; // 150% collateralization required
    uint256 public constant INTEREST_RATE = 5; // 5% annual interest rate
    
    address public owner;
    
    // Events
    event Deposited(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount, uint256 collateralAmount);
    event Repaid(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier validAmount(uint256 amount) {
        require(amount > 0, "Amount must be greater than 0");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Core Function 1: Deposit ETH to the lending pool
     * Users can deposit ETH to earn interest and provide liquidity
     */
    function deposit() external payable validAmount(msg.value) {
        deposits[msg.sender] += msg.value;
        totalDeposits += msg.value;
        
        emit Deposited(msg.sender, msg.value);
    }
    
    /**
     * @dev Core Function 2: Borrow ETH against collateral
     * Users can borrow up to 66.67% of their collateral value (150% collateralization)
     * @param borrowAmount The amount of ETH to borrow
     */
    function borrow(uint256 borrowAmount) external payable validAmount(borrowAmount) {
        require(msg.value > 0, "Collateral required");
        
        // Calculate required collateral (150% of borrow amount)
        uint256 requiredCollateral = (borrowAmount * COLLATERAL_RATIO) / 100;
        require(msg.value >= requiredCollateral, "Insufficient collateral");
        
        // Check if platform has enough liquidity
        require(address(this).balance >= borrowAmount + msg.value, "Insufficient liquidity");
        
        // Update user's collateral and borrowed amount
        collateral[msg.sender] += msg.value;
        borrowedAmounts[msg.sender] += borrowAmount;
        totalBorrowed += borrowAmount;
        
        // Transfer borrowed amount to user
        payable(msg.sender).transfer(borrowAmount);
        
        emit Borrowed(msg.sender, borrowAmount, msg.value);
    }
    
    /**
     * @dev Core Function 3: Repay borrowed amount and withdraw collateral
     * Users repay their debt and get their collateral back
     */
    function repay() external payable {
        uint256 borrowedAmount = borrowedAmounts[msg.sender];
        require(borrowedAmount > 0, "No active loan");
        
        // Calculate interest (simplified - in real implementation, time-based calculation needed)
        uint256 interest = (borrowedAmount * INTEREST_RATE) / 100;
        uint256 totalRepayment = borrowedAmount + interest;
        
        require(msg.value >= totalRepayment, "Insufficient repayment amount");
        
        // Update state
        uint256 userCollateral = collateral[msg.sender];
        borrowedAmounts[msg.sender] = 0;
        collateral[msg.sender] = 0;
        totalBorrowed -= borrowedAmount;
        
        // Return collateral to user
        payable(msg.sender).transfer(userCollateral);
        
        // Return excess repayment if any
        if (msg.value > totalRepayment) {
            payable(msg.sender).transfer(msg.value - totalRepayment);
        }
        
        emit Repaid(msg.sender, totalRepayment);
        emit CollateralWithdrawn(msg.sender, userCollateral);
    }
    
    // View functions
    function getUserDeposit(address user) external view returns (uint256) {
        return deposits[user];
    }
    
    function getUserBorrowedAmount(address user) external view returns (uint256) {
        return borrowedAmounts[user];
    }
    
    function getUserCollateral(address user) external view returns (uint256) {
        return collateral[user];
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function calculateMaxBorrow(uint256 collateralAmount) external pure returns (uint256) {
        return (collateralAmount * 100) / COLLATERAL_RATIO;
    }
    
    // Emergency function (only owner)
    function emergencyWithdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
    
    // Fallback function to receive ETH
    receive() external payable {
        // Allow contract to receive ETH
    }
}
