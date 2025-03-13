// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Script} from "forge-std/Script.sol";

import {IdentityRegistry} from "@erc3643/contracts/registry/implementation/IdentityRegistry.sol";
import {IIdentity} from "@onchain-id/solidity/contracts/interface/IIdentity.sol";

import {AddressConstants} from "./utils/constants.sol";

contract RegisterKYCCountry is Script {
    IdentityRegistry public identityRegistry;
    address public owner;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        owner = vm.addr(deployerPrivateKey);

        identityRegistry = IdentityRegistry(
            AddressConstants.IDENTITY_REGISTRY_ADDRESS
        );
        //Register KYC Country
        vm.startBroadcast(deployerPrivateKey);
        identityRegistry.registerIdentity(
            AddressConstants.USER_TOKEN_SENDER,
            IIdentity(AddressConstants.ONCHAIN_ID_ADDRESS),
            55 // Brazil
        );

        //Register KYC Country
        identityRegistry.registerIdentity(
            AddressConstants.USER_TOKEN_RECEIVER,
            IIdentity(AddressConstants.ONCHAIN_ID_ADDRESS),
            55 // Brazil
        );
        vm.stopBroadcast();
    }
}
