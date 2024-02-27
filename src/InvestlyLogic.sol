// InvestlyLogic.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC20.sol";
import "./InvestlyState.sol";
import {OrallyConsumer} from "./icp-orally-interfaces/OrallyConsumer.sol";

contract InvestlyLogic is OrallyConsumer {
    InvestlyState public state;
    address public exchangeProxy;

    event Deposit(address indexed token, address indexed user, uint256 amount, uint32 indexed subId);
    event Withdraw(address indexed token, address indexed user, uint256 amount, uint32 indexed subId);
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

    constructor(address _executorsRegistry, address _stateAddress, address _exchangeProxy) OrallyConsumer(_executorsRegistry) {
        state = InvestlyState(_stateAddress);
    }

    // Payable fallback to allow this contract to receive protocol fee refunds.
    receive() external payable {}

    function addSubscriptionWithDeposit(
        address sellToken,
        address buyToken,
        uint256 sellAmount,
        address spender,
        address swapTarget,
        bytes calldata swapCallData,
        uint256 value,
        uint256 depositAmount
    ) external returns (uint32) {
        uint32 subId = addSubscription(sellToken, buyToken, sellAmount, spender, swapTarget, swapCallData, value);

        depositToken(sellToken, depositAmount, subId);

        return subId;
    }

    function depositToken(address token, uint256 amount, uint32 subId) internal {
        require(IERC20(token).transferFrom(msg.sender, address(state), amount), "TRANSFER_FAILED");
        state.updateBalance(token, msg.sender, amount, true, subId);

        emit Deposit(token, msg.sender, amount, subId);
    }

    function withdrawToken(address token, uint256 amount, uint32 subId) external {
        state.updateBalance(token, msg.sender, amount, false, subId);
        require(IERC20(token).transferFrom(address(state), msg.sender, amount), "WITHDRAW_FAILED");

        emit Withdraw(token, msg.sender, amount, subId);
    }

    function addSubscription(
        address sellToken,
        address buyToken,
        uint256 sellAmount,
        address spender,
        address swapTarget,
        bytes calldata swapCallData,
        uint256 value
    ) internal returns (uint32) {
        uint32 subId = state.addSubscription(msg.sender, sellToken, buyToken, sellAmount, spender, swapTarget, swapCallData, value);

        emit SubscriptionAdded(subId, msg.sender, sellToken, buyToken, sellAmount, spender, swapTarget, swapCallData, value);

        return subId;
    }

    function removeSubscription(
        uint32 subId
    ) external {
        state.removeSubscription(subId);

        emit SubscriptionRemoved(subId);
    }

    function executeSwap(
        string memory, uint256 _subId, uint256, uint256
    ) external onlyExecutor {
        uint32 subId = uint32(_subId);
        (address user, address _sellToken, address _buyToken, uint256 sellAmount, address spender, address swapTarget, bytes memory swapCallData, uint256 value) = state.getSubscriptionDetails(subId);
        IERC20 sellToken = IERC20(_sellToken);
        IERC20 buyToken = IERC20(_buyToken);

        // Checks that the swapTarget is actually the address of 0x ExchangeProxy
        require(swapTarget == exchangeProxy, "Target not ExchangeProxy");

        // Track our balance of the buyToken to determine how much we've bought.
        uint256 boughtAmount = buyToken.balanceOf(address(this));

        // Ensure there's enough balance in the state contract for the sellToken
        state.updateBalance(_sellToken, user, sellAmount, false, subId);

        // Approve the spender to use the sellToken
        require(sellToken.approve(spender, uint256(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)));

        (bool success,) = swapTarget.call{value: value}(swapCallData);
        require(success, 'SWAP_CALL_FAILED');

        // Use our current buyToken balance to determine how much we've bought.
        boughtAmount = buyToken.balanceOf(address(this)) - boughtAmount;

        state.updateBalance(_buyToken, user, boughtAmount, true, subId);

        emit BoughtTokens(subId, _sellToken, _buyToken, boughtAmount);
    }
}
