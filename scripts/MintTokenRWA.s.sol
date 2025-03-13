// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Script} from "forge-std/Script.sol";
import {AddressConstants} from "./utils/constants.sol";
import {RWAToken} from "../src/RWAToken.sol";

contract MintTokenRWA is Script {
    RWAToken public realWorldAssetToken;

    address public owner;

    function run() public {
        /// ------------------------------------------------------------
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        owner = vm.addr(deployerPrivateKey);
        /// ------------------------------------------------------------

        realWorldAssetToken = RWAToken(AddressConstants.RWA_TOKEN_ADDRESS);

        vm.startBroadcast(deployerPrivateKey);
        realWorldAssetToken.mint(AddressConstants.USER_TOKEN_RECEIVER, 1 ether);
        vm.stopBroadcast();
    }
}
