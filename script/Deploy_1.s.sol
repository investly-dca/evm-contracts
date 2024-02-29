// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {InvestlyDCACoordinator} from "src/InvestlyDCACoordinatorV2.sol";

contract Deploy_1 is Script {
    address constant _executorsRegistry = 0xa5d1D2f23DaD7fDbB57BE3f0961a3D4ffdd4039A; // =
    address constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    function run() public {
        console2.log("Running deploy script for the Factory contract");
        vm.startBroadcast();

        InvestlyDCACoordinator DCACoordinator = new InvestlyDCACoordinator(UNISWAP_V3_ROUTER, _executorsRegistry);
        console2.log("InvestlyDCACoordinator deployed at:", address(DCACoordinator));

        vm.stopBroadcast();
    }
}
