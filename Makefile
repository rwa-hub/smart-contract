# Variáveis de configuração
TREX_DIR := lib/T-REX
FORGE := forge
NPM := npm
GIT := git
PRIVATE_KEY := 0xae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f

# Cores para output
GREEN := \033[0;32m
RED := \033[0;31m
YELLOW := \033[0;33m
NC := \033[0m # No Color

.PHONY: all install update clean remove build test reset-submodules install-deps help trex-setup trex-build trex-test check clean-deployments deploy

# Target padrão mostra o help
.DEFAULT_GOAL := help

all: install build test

help:
	@echo "$(GREEN)Comandos disponíveis:$(NC)"
	@echo "  $(YELLOW)make install$(NC)         - Instala todas as dependências (Forge e npm)"
	@echo "  $(YELLOW)make update$(NC)          - Atualiza todas as dependências"
	@echo "  $(YELLOW)make build$(NC)           - Compila todos os contratos"
	@echo "  $(YELLOW)make test$(NC)            - Executa todos os testes"
	@echo "  $(YELLOW)make clean$(NC)           - Remove arquivos de build"
	@echo "  $(YELLOW)make check$(NC)           - Executa verificações de qualidade de código"
	@echo "  $(YELLOW)make reset-submodules$(NC)- Reseta e reinicializa submódulos"
	@echo "  $(YELLOW)make install-dep$(NC)     - Instala uma nova dependência Forge (use dep=nome)"
	@echo "  $(YELLOW)make clean-deployments$(NC) - Limpa cache de deployments"
	@echo "  $(YELLOW)make deploy$(NC)          - Realiza o deploy dos contratos"

# Reseta e reinicializa os submódulos
reset-submodules:
	@echo "$(YELLOW)Resetando submódulos...$(NC)"
	@$(GIT) submodule deinit -f --all
	@rm -rf .git/modules/*
	@rm -rf lib/
	@$(GIT) submodule update --init --recursive
	@echo "$(GREEN)Submódulos resetados com sucesso!$(NC)"

# Configura T-REX
trex-setup:
	@echo "$(YELLOW)Configurando T-REX...$(NC)"
	@cd $(TREX_DIR) && $(NPM) install
	@echo "$(GREEN)T-REX configurado com sucesso!$(NC)"

# Compila T-REX
trex-build:
	@echo "$(YELLOW)Compilando T-REX...$(NC)"
	@cd $(TREX_DIR) && $(NPM) run build
	@echo "$(GREEN)T-REX compilado com sucesso!$(NC)"

# Testa T-REX
trex-test:
	@echo "$(YELLOW)Testando T-REX...$(NC)"
	@cd $(TREX_DIR) && $(NPM) test
	@echo "$(GREEN)Testes T-REX concluídos!$(NC)"

# Instala todas as dependências
install: reset-submodules trex-setup
	@echo "$(YELLOW)Instalando dependências Forge...$(NC)"
	@$(FORGE) install
	@echo "$(YELLOW)Gerando remappings...$(NC)"
	@$(FORGE) remappings > remappings.txt
	@echo "$(GREEN)Todas as dependências instaladas com sucesso!$(NC)"

# Atualiza todas as dependências
update:
	@echo "$(YELLOW)Atualizando dependências...$(NC)"
	@$(GIT) submodule update --remote --merge
	@$(FORGE) update
	@cd $(TREX_DIR) && $(NPM) update
	@echo "$(GREEN)Dependências atualizadas com sucesso!$(NC)"

# Remove os arquivos de build
clean:
	@echo "$(YELLOW)Limpando arquivos de build...$(NC)"
	@$(FORGE) clean
	@cd $(TREX_DIR) && $(NPM) run clean
	@echo "$(GREEN)Limpeza concluída!$(NC)"

# Remove todas as dependências
remove:
	@echo "$(YELLOW)Removendo dependências...$(NC)"
	@rm -rf lib/
	@echo "$(GREEN)Dependências removidas com sucesso!$(NC)"

# Compila os contratos
build: trex-build
	@echo "$(YELLOW)Compilando contratos...$(NC)"
	@$(FORGE) build
	@echo "$(GREEN)Contratos compilados com sucesso!$(NC)"

# Roda os testes
test: trex-test
	@echo "$(YELLOW)Executando testes Forge...$(NC)"
	@$(FORGE) test
	@echo "$(GREEN)Todos os testes concluídos com sucesso!$(NC)"

# Verificações de qualidade de código
check:
	@echo "$(YELLOW)Executando verificações de código...$(NC)"
	@cd $(TREX_DIR) && $(NPM) run lint
	@$(FORGE) fmt --check
	@echo "$(GREEN)Verificações concluídas!$(NC)"

# Instala uma nova dependência
install-dep:
	@if [ "$(dep)" = "" ]; then \
		echo "$(RED)Erro: Especifique a dependência com dep=nome$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Instalando dependência: $(dep)$(NC)"
	@$(FORGE) install $(dep)
	@echo "$(GREEN)Dependência instalada com sucesso!$(NC)"

# Limpa cache de deployments
clean-deployments:
	@echo "$(YELLOW)Limpando cache de deployments...$(NC)"
	@rm -rf broadcast/
	@rm -rf cache/
	@echo "$(GREEN)Cache de deployments limpo!$(NC)"

# Deploy dos contratos
deploy:
	@echo "$(YELLOW)Iniciando deploy dos contratos...$(NC)"
	@export PRIVATE_KEY=$(PRIVATE_KEY) && $(FORGE) script scripts/Deploy.s.sol --broadcast --verify
	@node scripts/save-addresses.js
	@echo "$(GREEN)Deploy concluído com sucesso!$(NC)"
