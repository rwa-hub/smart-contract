// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AbstractModule} from "@erc3643/contracts/compliance/modular/modules/AbstractModule.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// 🔹 Custom Errors para otimizar consumo de gas
error InvalidPropertyData(string reason);
error PropertyNotRegistered(uint256 matriculaId);
error UnauthorizedAccess(address caller);
error ComplianceCheckFailed(
    address from,
    address to,
    uint256 value,
    string reason
);
error DuplicateRegistry(uint256 matriculaId);
error PropertyTransferNotAllowed(uint256 matriculaId);

contract RegistryMDCompliance is AbstractModule, OwnableUpgradeable {
    enum PropertyType {
        URBANO,
        RURAL,
        LITORAL
    }

    struct PropertyInfo {
        uint256 matriculaId;
        uint256 folha;
        uint16 oficio;
        string nomeOficio;
        string comarca;
        string endereco;
        uint256 metragem;
        address proprietario;
        uint256 matriculaOrigem;
        uint256 iptu;
        uint256 itr;
        PropertyType tipo;
        bool isRegular;
    }

    mapping(uint256 => PropertyInfo) private _properties;
    mapping(uint256 => string[]) private _historicoAverbacoes;

    /// 🔹 Eventos para auditoria
    event PropertyRegistered(
        uint256 indexed matriculaId,
        address indexed proprietario
    );
    event PropertyUpdated(uint256 indexed matriculaId);
    event PropertyTransferred(
        uint256 indexed matriculaId,
        address indexed from,
        address indexed to
    );
    event AverbacaoAdded(uint256 indexed matriculaId, string averbacao);

    function init() external initializer {
        __Ownable_init();
    }

    /// 🔹 Registro de imóvel
    function registerProperty(
        uint256 matriculaId,
        uint256 folha,
        uint16 oficio,
        string memory nomeOficio,
        string memory comarca,
        string memory endereco,
        uint256 metragem,
        address proprietario,
        uint256 matriculaOrigem,
        uint256 iptu,
        uint256 itr,
        PropertyType tipo
    ) external onlyOwner {
        if (_properties[matriculaId].matriculaId != 0) {
            revert DuplicateRegistry(matriculaId);
        }

        _properties[matriculaId] = PropertyInfo(
            matriculaId,
            folha,
            oficio,
            nomeOficio,
            comarca,
            endereco,
            metragem,
            proprietario,
            matriculaOrigem,
            iptu,
            itr,
            tipo,
            true
        );

        emit PropertyRegistered(matriculaId, proprietario);
    }

    /// 🔹 Atualizar dados do imóvel
    function updateProperty(
        uint256 matriculaId,
        string memory endereco,
        uint256 metragem,
        uint256 iptu,
        uint256 itr,
        bool isRegular
    ) external onlyOwner {
        if (_properties[matriculaId].matriculaId == 0) {
            revert PropertyNotRegistered(matriculaId);
        }

        PropertyInfo storage prop = _properties[matriculaId];
        prop.endereco = endereco;
        prop.metragem = metragem;
        prop.iptu = iptu;
        prop.itr = itr;
        prop.isRegular = isRegular;

        emit PropertyUpdated(matriculaId);
    }

    /// 🔹 Adicionar averbação
    function addAverbacao(
        uint256 matriculaId,
        string memory averbacao
    ) external onlyOwner {
        if (_properties[matriculaId].matriculaId == 0) {
            revert PropertyNotRegistered(matriculaId);
        }

        _historicoAverbacoes[matriculaId].push(averbacao);
        emit AverbacaoAdded(matriculaId, averbacao);
    }

    /// 🔹 Transferência de propriedade
    function transferProperty(
        uint256 matriculaId,
        address novoProprietario
    ) external onlyOwner {
        if (_properties[matriculaId].matriculaId == 0) {
            revert PropertyNotRegistered(matriculaId);
        }
        if (!_properties[matriculaId].isRegular) {
            revert PropertyTransferNotAllowed(matriculaId);
        }

        address antigoProprietario = _properties[matriculaId].proprietario;
        _properties[matriculaId].proprietario = novoProprietario;

        emit PropertyTransferred(
            matriculaId,
            antigoProprietario,
            novoProprietario
        );
    }

    /// 🔹 Consulta de imóvel
    function getProperty(
        uint256 matriculaId
    ) external view returns (PropertyInfo memory) {
        if (_properties[matriculaId].matriculaId == 0) {
            revert PropertyNotRegistered(matriculaId);
        }
        return _properties[matriculaId];
    }

    /// 🔹 Consulta de averbações
    function getAverbacoes(
        uint256 matriculaId
    ) external view returns (string[] memory) {
        if (_properties[matriculaId].matriculaId == 0) {
            revert PropertyNotRegistered(matriculaId);
        }
        return _historicoAverbacoes[matriculaId];
    }

    /// 🔹 Validação de transferência de imóvel antes da venda
    function moduleCheck(
        address from,
        address to,
        uint256 matriculaId,
        address compliance
    ) external view override onlyBoundCompliance(compliance) returns (bool) {
        if (_properties[matriculaId].matriculaId == 0) {
            revert PropertyNotRegistered(matriculaId);
        }
        if (!_properties[matriculaId].isRegular) {
            revert ComplianceCheckFailed(
                from,
                to,
                matriculaId,
                "Imovel nao regularizado"
            );
        }
        return true;
    }

    function canComplianceBind(address) external pure override returns (bool) {
        return true;
    }

    function name() external pure override returns (string memory) {
        return "RegistryMDCompliance";
    }

    function isPlugAndPlay() external pure override returns (bool) {
        return true;
    }

    function moduleMintAction(address, uint256) external override {}

    function moduleBurnAction(address, uint256) external override {}

    function moduleTransferAction(
        address,
        address,
        uint256
    ) external override {}
}
