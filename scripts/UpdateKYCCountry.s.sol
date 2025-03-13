// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Script} from "forge-std/Script.sol";

import {IdentityRegistry} from "@erc3643/contracts/registry/implementation/IdentityRegistry.sol";
import {IIdentity} from "@onchain-id/solidity/contracts/interface/IIdentity.sol";

contract UpdateKYCCountry is Script {
    IdentityRegistry public identityRegistry;
    address public owner;
    // contracts addresses
    address public identityRegistryAddress =
        0x6EC5189503e0F03704B737d1977230c5b800A7F5;
    address public onchainIDAddress =
        0x66D5dD63fC9655a36B0bAe3BA619B7Cc2eCd6507;
    //user address
    address public userTokenSender = 0x98555970bf30BF7ed08Cf29BB08D432830b9b8bd;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        owner = vm.addr(deployerPrivateKey);

        identityRegistry = IdentityRegistry(identityRegistryAddress);
        /// @dev update the country of the userTokenSender to 55 (Turkey)
        vm.startBroadcast(deployerPrivateKey);
        identityRegistry.updateCountry(userTokenSender, 455);
        vm.stopBroadcast();
    }
}
