// InvestlyLogic.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC20.sol";
import "./InvestlyState.sol";
import {OrallyConsumer} from "./icp-orally-interfaces/OrallyConsumer.sol";

contract InvestlyLogic is OrallyConsumer {
    InvestlyState public state;
    address public exchangeProxy;

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
    event SubscriptionRemoved(uint32 indexed subscriptionId);
    event BoughtTokens(address indexed sellToken, address indexed buyToken, uint256 boughtAmount);

    constructor(address _executorsRegistry, address _stateAddress, address _exchangeProxy) OrallyConsumer(_executorsRegistry) {
        state = InvestlyState(_stateAddress);
    }

    // Payable fallback to allow this contract to receive protocol fee refunds.
    receive() external payable {}

    function depositToken(address token, uint256 amount) external {
        require(IERC20(token).transferFrom(msg.sender, address(state), amount), "TRANSFER_FAILED");
        state.updateBalance(token, msg.sender, amount, true);

        emit Deposit(token, msg.sender, amount);
    }

    function withdrawToken(address token, uint256 amount) external {
        state.updateBalance(token, msg.sender, amount, false);
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
    ) external {
        state.addSubscription(msg.sender, sellToken, buyToken, sellAmount, spender, swapTarget, swapCallData, value);

        emit SubscriptionAdded(state.subscriptionId(), user, sellToken, buyToken, spender, swapTarget, swapCallData, value);
    }

    function removeSubscription(
        uint32 subscriptionId
    ) external {
        state.removeSubscription(subscriptionId);

        emit SubscriptionRemoved(subscriptionId);
    }

    function executeSwap(
        string memory, uint256 _numeric, uint256, uint256
    ) external onlyExecutor {
        Subscription subscription = state.subscriptions(onlyExecutor);
        IERC20 sellToken = IERC20(subscription.sellToken);
        IERC20 buyToken = IERC20(subscription.buyToken);

        // Checks that the swapTarget is actually the address of 0x ExchangeProxy
        require(subscription.swapTarget == exchangeProxy, "Target not ExchangeProxy");

        // Track our balance of the buyToken to determine how much we've bought.
        uint256 boughtAmount = buyToken.balanceOf(address(this));

        // Ensure there's enough balance in the state contract for the sellToken
        state.updateBalance(subscription.sellToken, subscription.user, subscription.sellAmount, false);

        // Approve the spender to use the sellToken
        require(sellToken.approve(subscription.spender, uint256(-1)));

        (bool success,) = subscription.swapTarget.call{value: subscription.value}(subscription.swapCallData);
        require(success, 'SWAP_CALL_FAILED');

        // Use our current buyToken balance to determine how much we've bought.
        boughtAmount = buyToken.balanceOf(address(this)) - boughtAmount;

        state.updateBalance(subscription.buyToken, subscription.user, boughtAmount, true);

        emit BoughtTokens(subscription.sellToken, subscription.buyToken, boughtAmount);
    }
}
