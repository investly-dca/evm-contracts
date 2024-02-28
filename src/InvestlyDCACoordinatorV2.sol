// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;
pragma abicoder v2;

import "./IERC20.sol";
import {OrallyConsumer} from "./icp-orally-interfaces/OrallyConsumer.sol";

import 'node_modules/@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import 'node_modules/@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

contract InvestlyDCACoordinator is OrallyConsumer {
    address public owner;
    address public exchangeProxy;

    ISwapRouter public immutable swapRouter;
    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;

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

    constructor(ISwapRouter _swapRouter, address _executorsRegistry) OrallyConsumer(_executorsRegistry) {
        swapRouter = _swapRouter;
        owner = msg.sender;
    }

    // Payable fallback to allow this contract to receive protocol fee refunds.
    receive() external payable {}

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

    function executeSwap2(
        string memory, uint256 _subId, uint256, uint256
    ) external onlyExecutor {
        uint32 subId = uint32(_subId);
        Subscription storage subscription = subscriptions[subId];
        IERC20 sellToken = IERC20(subscription.sellToken);
        IERC20 buyToken = IERC20(subscription.buyToken);

        // Approve the router to spend token.
        TransferHelper.safeApprove(sellToken, address(swapRouter), subscription.sellAmount);

        // Ensure there's enough balance in the state contract for the sellToken
        _updateBalance(subscription.sellToken, subscription.user, subscription.sellAmount, false);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: subscription.sellToken,
                tokenOut: subscription.buyToken,
                fee: poolFee,
                recipient: address(this),
//                deadline: block.timestamp,
                amountIn: subscription.sellAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        boughtAmount = swapRouter.exactInputSingle(params);

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