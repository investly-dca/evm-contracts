// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;
pragma abicoder v2;

import {OrallyConsumer} from "./icp-orally-interfaces/OrallyConsumer.sol";

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

contract InvestlyDCACoordinator is OrallyConsumer {
    address public owner;

    ISwapRouter public immutable swapRouter;
    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;

    struct Subscription {
        address user;
        address sellToken;
        address buyToken;
        uint256 sellAmount;
    }

    // user => token => uint256
    mapping(address => mapping(address => uint256)) public tokenBalances;

    uint32 public subscriptionId = 1;
    mapping(uint32 => Subscription) public subscriptions;

    event Deposit(address indexed token, address indexed user, uint256 amount);
    event Withdraw(address indexed token, address indexed user, uint256 amount);
    event SubscriptionAdded(
        uint32 subId,
        address indexed user,
        address sellToken,
        address indexed buyToken,
        uint256 sellAmount
    );
    event SubscriptionRemoved(uint32 indexed subId);
    event BoughtTokens(uint32 indexed subId, address indexed sellToken, address indexed buyToken, uint256 boughtAmount);

    constructor(address _swapRouter, address _executorsRegistry) OrallyConsumer(_executorsRegistry) {
        swapRouter = ISwapRouter(_swapRouter);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    function depositToken(address token, uint256 amount) external {
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
        _updateBalance(token, msg.sender, amount, true);

        emit Deposit(token, msg.sender, amount);
    }

    function withdrawToken(address token, uint256 amount) external {
        _updateBalance(token, msg.sender, amount, false);
        TransferHelper.safeTransfer(token, msg.sender, amount);

        emit Withdraw(token, msg.sender, amount);
    }

    function addSubscription(
        address sellToken,
        address buyToken,
        uint256 sellAmount
    ) external returns (uint32) {
        uint32 subId = _addSubscription(msg.sender, sellToken, buyToken, sellAmount);

        emit SubscriptionAdded(subId, msg.sender, sellToken, buyToken, sellAmount);

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

        // Approve the router to spend token.
        TransferHelper.safeApprove(subscription.sellToken, address(swapRouter), subscription.sellAmount);

        // Ensure there's enough balance in the state contract for the sellToken
        _updateBalance(subscription.sellToken, subscription.user, subscription.sellAmount, false);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: subscription.sellToken,
                tokenOut: subscription.buyToken,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp + 1000,
                amountIn: subscription.sellAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        uint256 boughtAmount = swapRouter.exactInputSingle(params);

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
        uint256 sellAmount
    ) internal returns (uint32) {
        uint32 currentSubId = subscriptionId;

        subscriptions[currentSubId] = Subscription(user, sellToken, buyToken, sellAmount);

        subscriptionId++;

        return currentSubId;
    }

    function _removeSubscription(uint32 subId) internal {
        require(msg.sender == subscriptions[subId].user, "ONLY_SUBSCRIBER");

        delete subscriptions[subId];
    }
}