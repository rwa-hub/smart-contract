// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {RegistryMDCompliance} from "../src/compliances/RegistryMDCompliance.sol";
import {MockModularCompliance} from "./mocks/ModularComplianceMock.sol";

import {InvalidPropertyData, PropertyNotRegistered, UnauthorizedAccess, ComplianceCheckFailed, DuplicateRegistry, PropertyTransferNotAllowed} from "../src/compliances/RegistryMDCompliance.sol"; // Se desejar importar diretamente as errors

/**
 * @title RegistryMDComplianceTest
 * @dev Testes completos do contrato RegistryMDCompliance
 */
contract RegistryMDComplianceTest is Test {
    /// Instâncias
    RegistryMDCompliance public registryModule;
    MockModularCompliance public complianceMock;

    /// Endereços de teste
    address public owner;
    address public alice;
    address public bob;
    address public notOwner;
    uint256 public ownerPrivKey;
    uint256 public alicePrivKey;
    uint256 public bobPrivKey;

    // Matrícula fictícia
    uint256 public constant MATRICULA_ID = 101;
    uint256 public constant MATRICULA_ID2 = 202;

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

    // ========================================================
    // =============== Setup e Deploy do Contrato =============
    // ========================================================

    function setUp() public {
        /// Cria alguns endereços de teste
        (owner, ownerPrivKey) = makeAddrAndKey("owner");
        (alice, alicePrivKey) = makeAddrAndKey("alice");
        (bob, bobPrivKey) = makeAddrAndKey("bob");
        notOwner = makeAddr("notOwner");

        // Assume que o 'owner' faz as ações de implantação
        vm.startPrank(owner);

        // 1) Cria e inicializa o RegistryMDCompliance
        registryModule = new RegistryMDCompliance();
        registryModule.init(); // Chamamos initializer do Ownable + config

        // 2) Cria um mock de compliance (modular)
        complianceMock = new MockModularCompliance();
        complianceMock.init();

        // 3) Vincular o registryModule no compliance (para testar moduleCheck)
        complianceMock.addModule(address(registryModule));
        // Confirmar que binding deu certo
        bool isBound = registryModule.isComplianceBound(
            address(complianceMock)
        );
        console.log("isComplianceBound?", isBound);

        vm.stopPrank();
    }

    // ------------------------------------------------------------------------
    //            Testes de Eventos
    // ------------------------------------------------------------------------

    /**
     * @dev Testa se o evento PropertyRegistered é emitido corretamente
     */
    function testEventPropertyRegistered() public {
        vm.startPrank(owner);

        // Esperamos o evento:
        //   event PropertyRegistered(uint256 indexed matriculaId, address indexed proprietario);
        // Precisamos indicar quais parâmetros serão checados como 'indexed' no expectEmit:
        // - O 1º indexed (matriculaId) => true
        // - O 2º indexed (proprietario) => true
        // - data (sem indexed) => false
        // - topics (número de topics a comparar) => 2
        vm.expectEmit(true, true, false, false);
        // Agora indicamos o evento que esperamos:
        emit PropertyRegistered(MATRICULA_ID, alice);

        // Chamada que deve emitir
        registryModule.registerProperty(
            MATRICULA_ID,
            5,
            2,
            "Cartorio ABC",
            "Comarca 123",
            "Rua XYZ, 100",
            5000,
            alice,
            0,
            200,
            100,
            RegistryMDCompliance.PropertyType.URBANO
        );

        vm.stopPrank();
    }

    /**
     * @dev Testa se o evento PropertyUpdated é emitido ao chamar updateProperty
     */
    function testEventPropertyUpdated() public {
        // 1) Registrar a property antes
        vm.startPrank(owner);
        registryModule.registerProperty(
            MATRICULA_ID,
            1,
            1,
            "Oficio A",
            "Comarca A",
            "End A",
            2000,
            alice,
            0,
            100,
            50,
            RegistryMDCompliance.PropertyType.RURAL
        );

        // Esperamos o evento:
        //   event PropertyUpdated(uint256 indexed matriculaId);
        vm.expectEmit(true, false, false, false);
        emit PropertyUpdated(MATRICULA_ID);

        // 2) update
        registryModule.updateProperty(
            MATRICULA_ID,
            "Novo Endereco",
            999,
            111,
            222,
            false
        );
        vm.stopPrank();
    }

    /**
     * @dev Testa se o evento AverbacaoAdded é emitido ao chamar addAverbacao
     */
    function testEventAverbacaoAdded() public {
        // Registrar
        vm.startPrank(owner);
        registryModule.registerProperty(
            MATRICULA_ID,
            10,
            11,
            "OficioX",
            "ComarcaX",
            "Endereco X",
            8000,
            alice,
            0,
            200,
            100,
            RegistryMDCompliance.PropertyType.RURAL
        );

        // Esperamos:
        // event AverbacaoAdded(uint256 indexed matriculaId, string averbacao);
        //  1º indexed => MATRICULA_ID => true
        //  2º (averbacao) => não-indexed => false
        vm.expectEmit(true, false, false, false);
        emit AverbacaoAdded(MATRICULA_ID, "Averbacao 1");

        // Agora chamamos
        registryModule.addAverbacao(MATRICULA_ID, "Averbacao 1");
        vm.stopPrank();
    }

    /**
     * @dev Testa se o evento PropertyTransferred é emitido ao chamar transferProperty
     */
    function testEventPropertyTransferred() public {
        // registrar property
        vm.startPrank(owner);
        registryModule.registerProperty(
            MATRICULA_ID,
            2,
            2,
            "Oficio2",
            "Comarca2",
            "End2",
            1000,
            alice,
            0,
            55,
            25,
            RegistryMDCompliance.PropertyType.URBANO
        );

        // Esperamos:
        // event PropertyTransferred(
        //    uint256 indexed matriculaId,
        //    address indexed from,
        //    address indexed to
        // );
        // Indices => (true, true, true)
        vm.expectEmit(true, true, true, false);
        emit PropertyTransferred(MATRICULA_ID, alice, bob);

        registryModule.transferProperty(MATRICULA_ID, bob);
        vm.stopPrank();
    }

    // ========================================================
    // ============ Testes de inicialização e Owner ===========
    // ========================================================

    /// @dev Garante que o owner do RegistryMDCompliance é quem chamou init()
    function testOwnerAfterInit() public view {
        // O owner do registryModule deve ser 'owner'
        address modOwner = registryModule.owner();
        assertEq(modOwner, owner, "RegistryMDCompliance owner incorreto");
    }

    /// @dev Tenta chamar registerProperty com uma conta que não seja owner => reverte
    function testOnlyOwnerReverts() public {
        vm.startPrank(notOwner); // notOwner
        vm.expectRevert("Ownable: caller is not the owner");
        registryModule.registerProperty(
            999, // matriculaId
            10, // folha
            12, // oficio
            "OficioX",
            "ComarcaX",
            "Endereco X",
            1000, // metragem
            alice,
            0, // matriculaOrigem
            100,
            50,
            RegistryMDCompliance.PropertyType.URBANO
        );
        vm.stopPrank();
    }

    // ========================================================
    // ================ Testes de registerProperty ============
    // ========================================================

    /// @dev Fluxo feliz: registrar uma propriedade com sucesso
    function testRegisterPropertySuccess() public {
        vm.startPrank(owner);
        registryModule.registerProperty(
            MATRICULA_ID,
            5, // folha
            2, // oficio
            "Cartorio ABC",
            "Comarca 123",
            "Rua XYZ, 100",
            5000,
            alice, // proprietario
            0, // matriculaOrigem
            200, // iptu
            100, // itr
            RegistryMDCompliance.PropertyType.URBANO
        );
        vm.stopPrank();

        // Verifica se registrou
        // Chama getProperty(MATRICULA_ID)
        RegistryMDCompliance.PropertyInfo memory info = registryModule
            .getProperty(MATRICULA_ID);

        assertEq(info.matriculaId, MATRICULA_ID);
        assertEq(info.proprietario, alice);
        assertEq(info.isRegular, true, "Propriedade deve estar isRegular=true");
    }

    /// @dev Tenta registrar uma propriedade repetida => revert DuplicateRegistry
    function testRegisterPropertyDuplicate() public {
        // 1) Registrar a 1ª vez
        vm.startPrank(owner);
        registryModule.registerProperty(
            MATRICULA_ID,
            1, // ...
            1,
            "Oficio A",
            "Comarca A",
            "Rua Teste, 10",
            2000,
            alice,
            0,
            100,
            50,
            RegistryMDCompliance.PropertyType.RURAL
        );
        // 2) Registrar de novo a mesma matricula => revert
        vm.expectRevert(
            abi.encodeWithSelector(DuplicateRegistry.selector, MATRICULA_ID)
        );
        registryModule.registerProperty(
            MATRICULA_ID, // repete
            2,
            2,
            "Oficio B",
            "Comarca B",
            "Rua ABC, 20",
            3000,
            bob,
            0,
            150,
            75,
            RegistryMDCompliance.PropertyType.URBANO
        );

        vm.stopPrank();
    }

    // ========================================================
    // ================== Testes updateProperty ===============
    // ========================================================

    function testUpdatePropertySuccess() public {
        // Registrar
        vm.startPrank(owner);
        registryModule.registerProperty(
            MATRICULA_ID,
            1,
            1,
            "Oficio A",
            "Comarca A",
            "Endereco A",
            1000,
            alice,
            0,
            100,
            50,
            RegistryMDCompliance.PropertyType.URBANO
        );
        // Update
        registryModule.updateProperty(
            MATRICULA_ID,
            "Novo Endereco",
            500,
            200,
            100,
            false // isRegular
        );
        vm.stopPrank();

        RegistryMDCompliance.PropertyInfo memory info = registryModule
            .getProperty(MATRICULA_ID);
        assertEq(info.endereco, "Novo Endereco");
        assertEq(info.metragem, 500);
        assertEq(
            info.isRegular,
            false,
            "Deve estar isRegular=false depois do update"
        );
    }

    /// @dev Tenta update de uma property que não existe => revert PropertyNotRegistered
    function testUpdatePropertyNotRegistered() public {
        vm.startPrank(owner);

        vm.expectRevert(
            abi.encodeWithSelector(PropertyNotRegistered.selector, 777)
        );
        registryModule.updateProperty(
            777, // nao registrado
            "EnderecoX",
            999,
            111,
            222,
            true
        );
        vm.stopPrank();
    }

    // ========================================================
    // ================ Testes addAverbacao ===================
    // ========================================================

    /// @dev Fluxo feliz: addAverbacao
    function testAddAverbacaoSuccess() public {
        // registrar
        vm.startPrank(owner);
        registryModule.registerProperty(
            MATRICULA_ID,
            10,
            11,
            "OficioX",
            "ComarcaX",
            "Endereco X",
            8000,
            alice,
            0,
            200,
            100,
            RegistryMDCompliance.PropertyType.RURAL
        );
        // addAverbacao
        registryModule.addAverbacao(MATRICULA_ID, "Averbacao 1");
        registryModule.addAverbacao(MATRICULA_ID, "Averbacao 2");
        vm.stopPrank();

        // getAverbacoes
        string[] memory averbacoes = registryModule.getAverbacoes(MATRICULA_ID);
        assertEq(averbacoes.length, 2);
        assertEq(averbacoes[0], "Averbacao 1");
        assertEq(averbacoes[1], "Averbacao 2");
    }

    /// @dev addAverbacao em propriedade inexistente => revert
    function testAddAverbacaoFailNotRegistered() public {
        vm.startPrank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(PropertyNotRegistered.selector, 999)
        );
        registryModule.addAverbacao(999, "X");
        vm.stopPrank();
    }

    /// @dev getAverbacoes para matricula inexistente => revert
    function testGetAverbacoesFailNotRegistered() public {
        vm.expectRevert(
            abi.encodeWithSelector(PropertyNotRegistered.selector, 111)
        );
        registryModule.getAverbacoes(111);
    }

    // ========================================================
    // ============== Testes transferProperty =================
    // ========================================================

    /// @dev Fluxo feliz: transferProperty
    function testTransferPropertySuccess() public {
        // registrar e setar isRegular=true
        vm.startPrank(owner);
        registryModule.registerProperty(
            MATRICULA_ID,
            2,
            2,
            "Oficio2",
            "Comarca2",
            "End2",
            1000,
            alice,
            0,
            55,
            25,
            RegistryMDCompliance.PropertyType.URBANO
        );
        vm.stopPrank();

        // Transfer
        vm.startPrank(owner);
        registryModule.transferProperty(MATRICULA_ID, bob);
        vm.stopPrank();

        // Verificar se proprietario agora é bob
        RegistryMDCompliance.PropertyInfo memory info = registryModule
            .getProperty(MATRICULA_ID);
        assertEq(info.proprietario, bob, "owner da property deveria ser bob");
    }

    /// @dev Tenta transferProperty de matricula inexistente => revert
    function testTransferPropertyNotRegistered() public {
        vm.startPrank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(PropertyNotRegistered.selector, 987)
        );
        registryModule.transferProperty(987, bob);
        vm.stopPrank();
    }

    /// @dev Tenta transferProperty de property isRegular=false => revert
    function testTransferPropertyNotRegular() public {
        vm.startPrank(owner);
        // registrar com isRegular=false
        registryModule.registerProperty(
            MATRICULA_ID2,
            1,
            1,
            "CartorioX",
            "ComarcaZ",
            "EnderecoZ",
            900,
            alice,
            0,
            100,
            50,
            RegistryMDCompliance.PropertyType.LITORAL
        );
        // Em seguida, definimos isRegular=false via update
        registryModule.updateProperty(
            MATRICULA_ID2,
            "XYZ",
            900,
            100,
            50,
            false
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                PropertyTransferNotAllowed.selector,
                MATRICULA_ID2
            )
        );
        registryModule.transferProperty(MATRICULA_ID2, bob);
        vm.stopPrank();
    }

    // ========================================================
    // ================ Testes getProperty ====================
    // ========================================================

    function testGetPropertyFailNotRegistered() public {
        // property 999 não registrada
        vm.expectRevert(
            abi.encodeWithSelector(PropertyNotRegistered.selector, 999)
        );
        registryModule.getProperty(999);
    }

    // ========================================================
    // ================ Testes moduleCheck ====================
    // ========================================================

    /// @dev Fluxo feliz: moduleCheck => true
    function testModuleCheckSuccess() public {
        // 1) Registrar property e setar isRegular
        vm.startPrank(owner);
        registryModule.registerProperty(
            MATRICULA_ID,
            1,
            1,
            "Of A",
            "Com A",
            "End A",
            1000,
            alice,
            0,
            100,
            50,
            RegistryMDCompliance.PropertyType.URBANO
        );
        // isRegular (default é true)
        vm.stopPrank();

        // 2) Chamar moduleCheck
        bool success = registryModule.moduleCheck(
            alice,
            bob,
            MATRICULA_ID,
            address(complianceMock)
        );
        assertTrue(success, "moduleCheck deve retornar true se isRegular=true");
    }

    /// @dev moduleCheck falha se property inexistente
    function testModuleCheckFailNotRegistered() public {
        vm.expectRevert(
            abi.encodeWithSelector(PropertyNotRegistered.selector, 777)
        );
        registryModule.moduleCheck(alice, bob, 777, address(complianceMock));
    }

    /// @dev moduleCheck falha se property !isRegular
    function testModuleCheckFailNotRegular() public {
        vm.startPrank(owner);
        // registrar e setar isRegular=false
        registryModule.registerProperty(
            MATRICULA_ID,
            1,
            1,
            "Of X",
            "Com X",
            "End X",
            1000,
            alice,
            0,
            50,
            25,
            RegistryMDCompliance.PropertyType.RURAL
        );
        // update p/ isRegular=false
        registryModule.updateProperty(
            MATRICULA_ID,
            "End X2",
            500,
            60,
            30,
            false
        );
        vm.stopPrank();

        vm.expectRevert(
            abi.encodeWithSelector(
                ComplianceCheckFailed.selector,
                alice,
                bob,
                MATRICULA_ID,
                "Imovel nao regularizado"
            )
        );
        registryModule.moduleCheck(
            alice,
            bob,
            MATRICULA_ID,
            address(complianceMock)
        );
    }

    /// @dev moduleCheck falha se compliance não estiver bound (ex.: remover)
    function testModuleCheckFailNotBound() public {
        // remover module do compliance
        vm.startPrank(owner);
        complianceMock.removeModule(address(registryModule));
        vm.stopPrank();

        // Tentar moduleCheck => “compliance not bound”
        // Precisamos registrar a property senão dá outro erro
        vm.startPrank(owner);
        registryModule.registerProperty(
            MATRICULA_ID,
            1,
            1,
            "Of Y",
            "Com Y",
            "End Y",
            500,
            alice,
            0,
            50,
            25,
            RegistryMDCompliance.PropertyType.URBANO
        );
        vm.stopPrank();

        // now moduleCheck
        vm.expectRevert("compliance not bound");
        registryModule.moduleCheck(
            alice,
            bob,
            MATRICULA_ID,
            address(complianceMock)
        );
    }
}
