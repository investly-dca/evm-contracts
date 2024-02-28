// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../src/IERC20.sol";
import "../src/InvestlyDCACoordinator.sol";


contract ForkTest is Test {
    address constant FAKE_COORDINATOR_ADDRESS = 0xf7949AB6AFDfbF754C6B0247b93c77eE3710d9d0;
    address constant DEPLOYED_COORDINATOR_ADDRESS = 0x8DbC925568f81757a247BEabC9161A67929F08af;

    address constant ZERO_X_EXCHANGE_PROXY_ADDRESS = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;
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
        arbitrumFork = vm.createFork("https://arbitrum-mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID");
        vm.selectFork(arbitrumFork);

//        DCACoordinator = new InvestlyDCACoordinator(ORALLY_EXECUTORS_REGISTRY, ZERO_X_EXCHANGE_PROXY_ADDRESS);
        DCACoordinator = InvestlyDCACoordinator(DEPLOYED_COORDINATOR_ADDRESS);
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
            1000000,
            ZERO_X_EXCHANGE_PROXY_ADDRESS,
            ZERO_X_EXCHANGE_PROXY_ADDRESS,
            "0x415565b0000000000000000000000000fd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9000000000000000000000000fa7f8980b0f1e64a2062791cc3b0871572f1f7f000000000000000000000000000000000000000000000000000000000000f4240000000000000000000000000000000000000000000000000014e97dfd8aa052b00000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000420000000000000000000000000000000000000000000000000000000000000052000000000000000000000000000000000000000000000000000000000000000150000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000036000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9000000000000000000000000fa7f8980b0f1e64a2062791cc3b0871572f1f7f000000000000000000000000000000000000000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000320000000000000000000000000000000000000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000002e000000000000000000000000000000000000000000000000000000000000f4240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000012556e697377617056330000000000000000000000000000000000000000000000000000000000000000000000000f4240000000000000000000000000000000000000000000000000014f188d1d301bbc000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000e592427a0aece92de3edee1f18e0157c0586156400000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002bfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb90001f4fa7f8980b0f1e64a2062791cc3b0871572f1f7f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000fa7f8980b0f1e64a2062791cc3b0871572f1f7f0000000000000000000000000000000000000000000000000000080ad44861691000000000000000000000000ad01c20d5886137e056775af56915de824c8fce50000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000002000000000000000000000000fd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000869584cd0000000000000000000000002c22c7697455921f81b6070be51413d342e866cd00000000000000000000000000000000f289360bb7da3625d180615a837c998f",
            0
        );
        uint32 subId = 1;

        // check deposited user balance
        uint256 amount = DCACoordinator.tokenBalances(USER, USDT_ADDRESS);
        assertEq(amount, 10000000);

        // usdt balance should be increased
        assertEq(usdt.balanceOf(address(DCACoordinator)), 10000000);

        // should subscription be added
        (address user, address sellToken, address buyToken, uint256 sellAmount, address spender, address swapTarget, bytes memory swapCallData, uint256 value) = DCACoordinator.subscriptions(subId);
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
        usdt.approve(address(ZERO_X_EXCHANGE_PROXY_ADDRESS), 10000000);

        DCACoordinator.depositToken(USDT_ADDRESS, 10000000);

        DCACoordinator.addSubscription(
            USDT_ADDRESS,
            UNI_ADDRESS,
            1000000,
            ZERO_X_EXCHANGE_PROXY_ADDRESS,
            ZERO_X_EXCHANGE_PROXY_ADDRESS,
            "0x415565b0000000000000000000000000fd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9000000000000000000000000fa7f8980b0f1e64a2062791cc3b0871572f1f7f000000000000000000000000000000000000000000000000000000000000f42400000000000000000000000000000000000000000000000000153f0a918609f8500000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000420000000000000000000000000000000000000000000000000000000000000052000000000000000000000000000000000000000000000000000000000000000150000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000036000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9000000000000000000000000fa7f8980b0f1e64a2062791cc3b0871572f1f7f000000000000000000000000000000000000000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000320000000000000000000000000000000000000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000002e000000000000000000000000000000000000000000000000000000000000f42400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000025375736869537761700000000000000000000000000000000000000000000000000000000000000000000000000f424000000000000000000000000000000000000000000000000001547364c43114ab000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000001b02da8cb0d097eb8d57a175b88c7d8b4799750600000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000003000000000000000000000000fd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb900000000000000000000000082af49447d8a07e3bd95bd0d56f35241523fbab1000000000000000000000000fa7f8980b0f1e64a2062791cc3b0871572f1f7f0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000fa7f8980b0f1e64a2062791cc3b0871572f1f7f0000000000000000000000000000000000000000000000000000082bbabd07526000000000000000000000000ad01c20d5886137e056775af56915de824c8fce50000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000002000000000000000000000000fd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000869584cd00000000000000000000000010000000000000000000000000000000000000110000000000000000000000000000000053e021394c8f78b031f20793480204d8",
            0
        );
        uint32 subId = 1;

        vm.stopPrank();

//        vm.startPrank(address(DCACoordinator));
//        usdt.approve(address(ZERO_X_EXCHANGE_PROXY_ADDRESS), 10000000);
//        vm.stopPrank();

        vm.startPrank(address(DCACoordinator));
        usdt.approve(ZERO_X_EXCHANGE_PROXY_ADDRESS, 10000000);

        vm.stopPrank();

        usdt.approve(ZERO_X_EXCHANGE_PROXY_ADDRESS, 10000000);

        DCACoordinator.executeSwap("0x...", subId, 0, 0);



        uint256 amount = DCACoordinator.tokenBalances(USER, USDT_ADDRESS);
        assertEq(amount, 9000000);
        assertEq(usdt.balanceOf(address(DCACoordinator)), 9000000);

        uint256 amountBought = DCACoordinator.tokenBalances(USER, UNI_ADDRESS);
        assertEq(amountBought, 1000000);

        vm.stopPrank();
    }
}
