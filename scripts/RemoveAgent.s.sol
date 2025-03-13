// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Script} from "forge-std/Script.sol";

import {AddressConstants} from "./utils/constants.sol";

import {RWAToken} from "../src/RWAToken.sol";

contract RemoveAgent is Script {
    RWAToken public realWorldAssetToken;

    address public testAddress = 0x293D0b9eF2990BC8093E346eeC39e3fc552A3b09;

    function run() public {
        /// ------------------------------------------------------------
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        /// ------------------------------------------------------------
        realWorldAssetToken = RWAToken(AddressConstants.RWA_TOKEN_ADDRESS);

        vm.startBroadcast(deployerPrivateKey);
        realWorldAssetToken.removeAgent(testAddress);
        vm.stopBroadcast();
    }
}
