// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Script} from "forge-std/Script.sol";

import {FinancialCompliance} from "../src/compliances/FinancialCompliance.sol";
import {AddressConstants} from "./utils/constants.sol";

import {IdentityRegistry} from "@erc3643/contracts/registry/implementation/IdentityRegistry.sol";
import {ModularCompliance} from "@erc3643/contracts/compliance/modular/ModularCompliance.sol";

// Contracts from Onchain-ID
import {Identity} from "@onchain-id/solidity/contracts/Identity.sol";
import {TrustedIssuersRegistry} from "@erc3643/contracts/registry/implementation/TrustedIssuersRegistry.sol";
import {ClaimTopicsRegistry} from "@erc3643/contracts/registry/implementation/ClaimTopicsRegistry.sol";
import {IdentityRegistryStorage} from "@erc3643/contracts/registry/implementation/IdentityRegistryStorage.sol";

import {RWAToken} from "../src/RWAToken.sol";

contract AddAgent is Script {
    IdentityRegistry public identityRegistry;
    IdentityRegistryStorage public identityRegistryStorage;
    RWAToken public realWorldAssetToken;

    address public owner;

    address public testAddress = 0x293D0b9eF2990BC8093E346eeC39e3fc552A3b09;

    function run() public {
        /// ------------------------------------------------------------
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        owner = vm.addr(deployerPrivateKey);
        /// ------------------------------------------------------------

        /// @dev
        identityRegistry = IdentityRegistry(
            AddressConstants.IDENTITY_REGISTRY_ADDRESS
        );
        identityRegistryStorage = IdentityRegistryStorage(
            AddressConstants.IDENTITY_REGISTRY_STORAGE_ADDRESS
        );
        realWorldAssetToken = RWAToken(AddressConstants.RWA_TOKEN_ADDRESS);

        vm.startBroadcast(deployerPrivateKey);
        // identityRegistryStorage.addAgent(testAddress);
        // identityRegistry.addAgent(testAddress);
        realWorldAssetToken.addAgent(testAddress);
        vm.stopBroadcast();
    }
}
