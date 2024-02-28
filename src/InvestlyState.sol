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
        // The `sellAmount` field from the API response.
        uint256 sellAmount;
        // The `allowanceTarget` field from the API response.
        address spender;
        // The `to` field from the API response.
        address swapTarget;
        // The `data` field from the API response.
        bytes swapCallData;
        // The `value` field from the API response.
        uint256 value;
    }

contract InvestlyState {
    address public owner;
    address public logicContract;

    struct Balance {
        address tokenAddress;
        uint256 amount;
    }

    struct BoughtTokens {
        address buyToken;
        uint256 boughtAmount;
    }

    // user => subId => balance
    mapping(address => mapping(uint32 => Balance)) public tokenBalances;

    // subId => subId => boughtTokens
    mapping(address => mapping(uint32 => BoughtTokens)) public boughtTokens;

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

    function updateBalance(address token, address user, uint256 amount, bool increase, uint32 subId) external onlyLogicContract {
        if (increase) {
            IERC20(token).approve(logicContract, amount);

            tokenBalances[user][subId].amount += amount;
            tokenBalances[user][subId].tokenAddress = token;
        } else {
            require(tokenBalances[user][subId].amount >= amount, "INSUFFICIENT_BALANCE");
            tokenBalances[user][subId].amount -= amount;
            tokenBalances[user][subId].tokenAddress = token;
        }
    }

    function updateBoughtTokens(address user, uint32 subId, address buyToken, uint256 boughtAmount) external onlyLogicContract {
        boughtTokens[user][subId] = BoughtTokens(buyToken, boughtAmount);
    }

    function addSubscription(
        address user,
        address sellToken,
        address buyToken,
        uint256 sellAmount,
        address spender,
        address swapTarget,
        bytes calldata swapCallData,
        uint256 value
    ) external onlyLogicContract returns (uint32) {
        uint32 currentSubId = subscriptionId;

        subscriptions[currentSubId] = Subscription(user, sellToken, buyToken, sellAmount, spender, swapTarget, swapCallData, value);

        subscriptionId++;

        return currentSubId;
    }

    function removeSubscription(uint32 subId) external onlyLogicContract {
        require(msg.sender == subscriptions[subId].user, "ONLY_SUBSCRIBER");

        delete subscriptions[subId];
    }

    function getSubscriptionDetails(uint32 subId) external view returns (address user, address sellToken, address buyToken, uint256 sellAmount, address spender, address swapTarget, bytes memory swapCallData, uint256 value) {
        Subscription storage subscription = subscriptions[subId];
        return (subscription.user, subscription.sellToken, subscription.buyToken, subscription.sellAmount, subscription.spender, subscription.swapTarget, subscription.swapCallData, subscription.value);
    }
}