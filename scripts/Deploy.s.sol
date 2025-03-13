// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {RWAToken} from "../src/RWAToken.sol";
import {FinancialCompliance} from "../src/compliances/FinancialCompliance.sol";

// Contracts from ERC3643
import {IdentityRegistry} from "@erc3643/contracts/registry/implementation/IdentityRegistry.sol";
import {ModularCompliance} from "@erc3643/contracts/compliance/modular/ModularCompliance.sol";

// Contracts from Onchain-ID
import {Identity} from "@onchain-id/solidity/contracts/Identity.sol";
import {TrustedIssuersRegistry} from "@erc3643/contracts/registry/implementation/TrustedIssuersRegistry.sol";
import {ClaimTopicsRegistry} from "@erc3643/contracts/registry/implementation/ClaimTopicsRegistry.sol";
import {IdentityRegistryStorage} from "@erc3643/contracts/registry/implementation/IdentityRegistryStorage.sol";

contract Deploy is Script {
    address public owner;

    /// @dev Instâncias de contrato
    RWAToken public rWAToken;
    FinancialCompliance public rwaCompliance;
    IdentityRegistry public identityRegistry;
    ModularCompliance public compliance;
    Identity public onchainID;

    ClaimTopicsRegistry public claimTopicsRegistry;
    IdentityRegistryStorage public identityRegistryStorage;
    TrustedIssuersRegistry public trustedIssuersRegistry;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        owner = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);
        trustedIssuersRegistry = new TrustedIssuersRegistry();
        console.log(
            "TrustedIssuersRegistry deployed at:",
            address(trustedIssuersRegistry)
        );
        claimTopicsRegistry = new ClaimTopicsRegistry();
        console.log(
            "ClaimTopicsRegistry deployed at:",
            address(claimTopicsRegistry)
        );
        identityRegistryStorage = new IdentityRegistryStorage();
        console.log(
            "IdentityRegistryStorage deployed at:",
            address(identityRegistryStorage)
        );
        identityRegistry = new IdentityRegistry();
        console.log("IdentityRegistry deployed at:", address(identityRegistry));
        compliance = new ModularCompliance();
        console.log("ModularCompliance deployed at:", address(compliance));
        onchainID = new Identity(owner, true);
        console.log("Identity deployed at:", address(onchainID));

        // /// ----------------- Deploy do contrato -----------------
        rwaCompliance = new FinancialCompliance();
        rWAToken = new RWAToken();

        // /// ----------------- Inicialização dos contratos -----------------
        identityRegistryStorage.init();
        trustedIssuersRegistry.init();
        claimTopicsRegistry.init();
        identityRegistry.init(
            address(trustedIssuersRegistry),
            address(claimTopicsRegistry),
            address(identityRegistryStorage)
        );
        compliance.init();
        rwaCompliance.init(5000 ether);
        rWAToken.init(
            address(identityRegistry),
            address(compliance),
            "RWAToken",
            "ATOKEN",
            18,
            address(onchainID)
        );

        console.log("Token deployed at:", address(rWAToken));
        console.log("Compliance deployed at:", address(rwaCompliance));
        console.log("IdentityRegistry deployed at:", address(identityRegistry));

        //🔹 Associa o módulo de compliance ao contrato de compliance mock
        compliance.addModule(address(rwaCompliance));
        rwaCompliance.transferOwnership(owner);

        /// 🔹 Adiciona o owner como agente supervisionador
        identityRegistryStorage.addAgent(owner);
        identityRegistryStorage.addAgent(address(identityRegistry));
        identityRegistry.addAgent(owner);
        rWAToken.addAgent(owner);

        vm.stopBroadcast();
    }
}
