// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../src/InvestlyDCACoordinatorV2.sol";


contract ForkTest is Test {
    address constant FAKE_COORDINATOR_ADDRESS = 0xf7949AB6AFDfbF754C6B0247b93c77eE3710d9d0;
    address constant DEPLOYED_COORDINATOR_ADDRESS = 0x8DbC925568f81757a247BEabC9161A67929F08af;

    address constant ZERO_X_EXCHANGE_PROXY_ADDRESS = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;
    address constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant ORALLY_EXECUTORS_REGISTRY = 0xa5d1D2f23DaD7fDbB57BE3f0961a3D4ffdd4039A;
    address constant ORALLY_MULTICALL = 0xb65dc3dDA0A47B7bE4c43fE8eE124986D12aCDA3;

    address constant USDT_ADDRESS = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address constant UNI_ADDRESS = 0xFa7F8980b0f1E64A2062791cc3b0871572f1F7f0;
    address constant USER = 0x2D60362EA2Ef3c4ffe80d237527Cf2a037A31919;

    uint256 arbitrumFork;
    InvestlyDCACoordinator DCACoordinator;
    IERC20 usdt;
    IERC20 uni;

    function setUp() public {
        arbitrumFork = vm.createFork("https://arbitrum-mainnet.infura.io/v3/{key}");
        vm.selectFork(arbitrumFork);

        DCACoordinator = new InvestlyDCACoordinator(UNISWAP_V3_ROUTER, ORALLY_EXECUTORS_REGISTRY);
//        DCACoordinator = InvestlyDCACoordinator(DEPLOYED_COORDINATOR_ADDRESS);
        usdt = IERC20(USDT_ADDRESS);
        uni = IERC20(UNI_ADDRESS);
    }

    function testAddSubscriptionWithDeposit() public {
        vm.selectFork(arbitrumFork);

        vm.startPrank(USER);

        usdt.approve(address(DCACoordinator), 10000000);

        DCACoordinator.depositToken(USDT_ADDRESS, 10000000);

        DCACoordinator.addSubscription(
            USDT_ADDRESS,
            UNI_ADDRESS,
            1000000
        );
        uint32 subId = 1;

        // check deposited user balance
        uint256 amount = DCACoordinator.tokenBalances(USER, USDT_ADDRESS);
        assertEq(amount, 10000000);

        // usdt balance should be increased
        assertEq(usdt.balanceOf(address(DCACoordinator)), 10000000);

        // should subscription be added
        (address user, address sellToken, address buyToken, uint256 sellAmount) = DCACoordinator.subscriptions(subId);
        assertEq(sellToken, USDT_ADDRESS);
        assertEq(buyToken, UNI_ADDRESS);
        assertEq(user, USER);

        // test withdraw
        DCACoordinator.withdrawToken(USDT_ADDRESS, 1000000);
        amount = DCACoordinator.tokenBalances(USER, USDT_ADDRESS);
        assertEq(amount, 9000000);
        assertEq(usdt.balanceOf(address(DCACoordinator)), 9000000);

        vm.stopPrank();
    }

    function testExecuteSwap() public {
        vm.selectFork(arbitrumFork);

        vm.startPrank(USER);

        usdt.approve(address(DCACoordinator), 10000000);

        DCACoordinator.depositToken(USDT_ADDRESS, 10000000);

        DCACoordinator.addSubscription(
            USDT_ADDRESS,
            UNI_ADDRESS,
            1000000
        );
        uint32 subId = 1;

        vm.stopPrank();

        vm.startPrank(address(ORALLY_MULTICALL));

        DCACoordinator.executeSwap("0x...", subId, 0, 0);

        vm.stopPrank();


        uint256 amount = DCACoordinator.tokenBalances(USER, USDT_ADDRESS);
        assertEq(amount, 9000000);
        assertEq(usdt.balanceOf(address(DCACoordinator)), 9000000);

        uint256 amountBought = DCACoordinator.tokenBalances(USER, UNI_ADDRESS);
        assertEq(amountBought > 0, true);

        vm.stopPrank();
    }
}
