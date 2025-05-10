#!/bin/bash

# Criar diretório para os PNGs se não existir
mkdir -p output

# Gerar PNGs com fundo transparente

mmdc -i flow.mmd -o output/flow.png -b transparent
mmdc -i roles.mmd -o output/roles.png -b transparent

echo "PNGs gerados com sucesso na pasta output/" 