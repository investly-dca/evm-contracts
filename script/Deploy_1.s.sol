// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {InvestlyState} from "src/InvestlyState.sol";
import {InvestlyLogic} from "src/InvestlyLogic.sol";

contract Deploy_1 is Script {
    address constant _executorsRegistry = 0xa5d1D2f23DaD7fDbB57BE3f0961a3D4ffdd4039A; // =
    address constant _exchangeProxy = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF; // =

    function run() public {
        console2.log("Running deploy script for the Factory contract");
        vm.startBroadcast();

        InvestlyState state = new InvestlyState();
        console2.log("InvestlyState deployed at:", address(state));

        InvestlyLogic logic = new InvestlyLogic(_executorsRegistry, address(state), _exchangeProxy);
        console2.log("InvestlyLogic deployed at:", address(logic));

        vm.stopBroadcast();
    }
}
