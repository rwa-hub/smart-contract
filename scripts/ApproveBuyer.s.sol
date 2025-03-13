// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Script} from "forge-std/Script.sol";

import {FinancialCompliance} from "../src/compliances/FinancialCompliance.sol";
import {AddressConstants} from "./utils/constants.sol";

contract ApproveBuyer is Script {
    FinancialCompliance public financialComplianceModule;
    address public owner;

    function run() public {
        /// ------------------------------------------------------------
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        owner = vm.addr(deployerPrivateKey);
        /// ------------------------------------------------------------

        financialComplianceModule = FinancialCompliance(
            AddressConstants.RWA_COMPLIANCE_ADDRESS
        );
        /// @dev approve the buyer to buy the token
        vm.startBroadcast(deployerPrivateKey);
        /// @dev Aprova um novo comprador após verificações de compliance
        /// @param buyer (address) Endereço do comprador a ser aprovado
        /// @param creditInsuranceApproved (bool) Status da aprovação do seguro de crédito
        /// @param serasaClearance (bool) Status da verificação no Serasa
        /// @param documentsVerified (bool) Status da verificação dos documentos
        /// @param income (uint256) Renda mensal do comprador em wei
        /// @param addressVerified (string) Endereço verificado do comprador
        /// @param saleRegistered (bool) Status do registro da venda
        /// @param signedAgreement (bool) Status da assinatura do contrato
        financialComplianceModule.approveBuyer(
            AddressConstants.USER_TOKEN_RECEIVER,
            true,
            true,
            true,
            10000 ether,
            "Rua dos Bobos, 0",
            true,
            true
        );
        vm.stopBroadcast();
    }
}
