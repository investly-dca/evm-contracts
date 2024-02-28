// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "./IERC20.sol";
import {OrallyConsumer} from "./icp-orally-interfaces/OrallyConsumer.sol";
import "forge-std/console.sol";

contract InvestlyDCACoordinator is OrallyConsumer {
    address public owner;
    address public exchangeProxy;

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

    // user => token => uint256
    mapping(address => mapping(address => uint256)) public tokenBalances;

    uint32 public subscriptionId = 1;
    mapping(uint32 => Subscription) public subscriptions;

    event Deposit(address indexed token, address indexed user, uint256 amount);
    event Withdraw(address indexed token, address indexed user, uint256 amount);
    event SubscriptionAdded(
        uint32 indexed subId,
        address indexed user,
        address sellToken,
        address indexed buyToken,
        uint256 sellAmount,
        address spender,
        address swapTarget,
        bytes swapCallData,
        uint256 value
    );
    event SubscriptionRemoved(uint32 indexed subId);
    event BoughtTokens(uint32 indexed subId, address indexed sellToken, address indexed buyToken, uint256 boughtAmount);

    constructor(address _executorsRegistry, address _exchangeProxy) OrallyConsumer(_executorsRegistry) {
        exchangeProxy = _exchangeProxy;
        owner = msg.sender;
    }

    // Payable fallback to allow this contract to receive protocol fee refunds.
    receive() external payable {}

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    function depositToken(address token, uint256 amount) external {
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "TRANSFER_FAILED");
        _updateBalance(token, msg.sender, amount, true);

        IERC20(token).approve(exchangeProxy, amount);

        emit Deposit(token, msg.sender, amount);
    }

    function withdrawToken(address token, uint256 amount) external {
        _updateBalance(token, msg.sender, amount, false);
        require(IERC20(token).transfer(msg.sender, amount), "WITHDRAW_FAILED");

        emit Withdraw(token, msg.sender, amount);
    }

    function addSubscription(
        address sellToken,
        address buyToken,
        uint256 sellAmount,
        address spender,
        address swapTarget,
        bytes calldata swapCallData,
        uint256 value
    ) external returns (uint32) {
        uint32 subId = _addSubscription(msg.sender, sellToken, buyToken, sellAmount, spender, swapTarget, swapCallData, value);

        emit SubscriptionAdded(subId, msg.sender, sellToken, buyToken, sellAmount, spender, swapTarget, swapCallData, value);

        return subId;
    }

    function removeSubscription(
        uint32 subId
    ) external {
        _removeSubscription(subId);

        emit SubscriptionRemoved(subId);
    }

    function executeSwap(
        string memory, uint256 _subId, uint256, uint256
    ) external onlyExecutor {
        uint32 subId = uint32(_subId);
        Subscription storage subscription = subscriptions[subId];
        IERC20 sellToken = IERC20(subscription.sellToken);
        IERC20 buyToken = IERC20(subscription.buyToken);

        console.logAddress(subscription.swapTarget);
        console.logAddress(exchangeProxy);
        // Checks that the swapTarget is actually the address of 0x ExchangeProxy
        require(subscription.swapTarget == exchangeProxy, "Target not ExchangeProxy");

        // Track our balance of the buyToken to determine how much we've bought.
        uint256 boughtAmount = buyToken.balanceOf(address(this));

        // Ensure there's enough balance in the state contract for the sellToken
        _updateBalance(subscription.sellToken, subscription.user, subscription.sellAmount, false);

        // Approve the spender to use the sellToken
        require(sellToken.approve(subscription.spender, uint256(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)));

        (bool success, bytes memory resultData) = subscription.swapTarget.call{value: subscription.value}(subscription.swapCallData);
        console.logBytes(resultData);
        console.logUint(abi.decode(resultData, (uint256)));
        console.logBool(success);
//        console.logUint(resultData);
        require(success, 'SWAP_CALL_FAILED');

        // Use our current buyToken balance to determine how much we've bought.
        boughtAmount = buyToken.balanceOf(address(this)) - boughtAmount;

        _updateBalance(subscription.buyToken, subscription.user, boughtAmount, true);

        emit BoughtTokens(subId, subscription.sellToken, subscription.buyToken, boughtAmount);
    }

    function _updateBalance(address token, address user, uint256 amount, bool increase) internal {
        if (increase) {
            tokenBalances[user][token] += amount;
        } else {
            require(tokenBalances[user][token] >= amount, "INSUFFICIENT_BALANCE");
            tokenBalances[user][token] -= amount;
        }
    }

    function _addSubscription(
        address user,
        address sellToken,
        address buyToken,
        uint256 sellAmount,
        address spender,
        address swapTarget,
        bytes calldata swapCallData,
        uint256 value
    ) internal returns (uint32) {
        uint32 currentSubId = subscriptionId;

        subscriptions[currentSubId] = Subscription(user, sellToken, buyToken, sellAmount, spender, swapTarget, swapCallData, value);

        subscriptionId++;

        return currentSubId;
    }

    function _removeSubscription(uint32 subId) internal {
        require(msg.sender == subscriptions[subId].user, "ONLY_SUBSCRIBER");

        delete subscriptions[subId];
    }
}