// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {InvestlyDCACoordinator} from "src/InvestlyDCACoordinator.sol";

contract Deploy_1 is Script {
    address constant _executorsRegistry = 0xa5d1D2f23DaD7fDbB57BE3f0961a3D4ffdd4039A; // =
    address constant _exchangeProxy = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF; // =

    function run() public {
        console2.log("Running deploy script for the Factory contract");
        vm.startBroadcast();

        InvestlyDCACoordinator DCACoordinator = new InvestlyDCACoordinator(_executorsRegistry, _exchangeProxy);
        console2.log("InvestlyDCACoordinator deployed at:", address(DCACoordinator));

        vm.stopBroadcast();
    }
}
