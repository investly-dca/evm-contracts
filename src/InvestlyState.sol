// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "./IERC20.sol";

    struct Subscription {
        // user
        address user;
        // The `sellTokenAddress` field from the API response.
        address sellToken;
        // The `buyTokenAddress` field from the API response.
        address buyToken;
        // The `allowanceTarget` field from the API response.
        address spender;
        // The `to` field from the API response.
        address payable swapTarget;
        // The `data` field from the API response.
        bytes calldata swapCallDat;
        // The `value` field from the API response.
        uint256 value;
    }

contract InvestlyState {
    address public owner;
    address public logicContract;

    event Deposit(address indexed token, address indexed user, uint256 amount);
    event Withdraw(address indexed token, address indexed user, uint256 amount);
    event SubscriptionAdded(
        uint32 indexed subscriptionId,
        address indexed user,
        address indexed sellToken,
        address indexed buyToken,
        uint256 sellAmount,
        address spender,
        address swapTarget,
        bytes swapCallData,
        uint256 value
    );

    // Mapping from token address to user address to balance
    mapping(address => mapping(address => uint256)) public tokenBalances;

    uint32 public subscriptionId = 1;
    mapping(uint32 => Subscription) public subscriptions;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    modifier onlyLogicContract() {
        require(msg.sender == logicContract, "ONLY_LOGIC_CONTRACT");
        _;
    }

    function setLogicContract(address _logicContract) external onlyOwner {
        logicContract = _logicContract;
    }

    function updateBalance(address token, address user, uint256 amount, bool increase) external onlyLogicContract {
        if (increase) {
            tokenBalances[token][user] += amount;

            emit Deposit(token, user, amount);
        } else {
            require(tokenBalances[token][user] >= amount, "INSUFFICIENT_BALANCE");
            tokenBalances[token][user] -= amount;

            emit Withdraw(token, user, amount);
        }
    }

    function addSubscription(
        address user,
        address sellToken,
        address buyToken,
        address spender,
        address payable swapTarget,
        bytes calldata swapCallData,
        uint256 value
    ) external onlyLogicContract {
        subscriptions[subscriptionId] = Subscription(user, sellToken, buyToken, spender, swapTarget, swapCallData, value);
        subscriptionId++;

        emit SubscriptionAdded(subscriptionId, user, sellToken, buyToken, spender, swapTarget, swapCallData, value);
    }
}