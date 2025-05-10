const fs = require('fs');
const path = require('path');

// Lê o arquivo de broadcast do último deploy
const BROADCAST_DIR = path.join(__dirname, '../broadcast');
const latestBroadcast = fs.readdirSync(BROADCAST_DIR)
  .filter(f => f.endsWith('.json'))
  .sort((a, b) => {
    return fs.statSync(path.join(BROADCAST_DIR, b)).mtime.getTime() - 
           fs.statSync(path.join(BROADCAST_DIR, a)).mtime.getTime();
  })[0];

if (!latestBroadcast) {
  console.error('❌ Nenhum arquivo de broadcast encontrado!');
  process.exit(1);
}

const broadcastData = JSON.parse(
  fs.readFileSync(path.join(BROADCAST_DIR, latestBroadcast))
);

// Extrai os endereços dos contratos
const addresses = {
  RWAToken: broadcastData.transactions.find(tx => tx.contractName === 'RWAToken')?.contractAddress,
  FinancialCompliance: broadcastData.transactions.find(tx => tx.contractName === 'FinancialCompliance')?.contractAddress,
  IdentityRegistry: broadcastData.transactions.find(tx => tx.contractName === 'IdentityRegistry')?.contractAddress,
  ModularCompliance: broadcastData.transactions.find(tx => tx.contractName === 'ModularCompliance')?.contractAddress,
  Identity: broadcastData.transactions.find(tx => tx.contractName === 'Identity')?.contractAddress,
  ClaimTopicsRegistry: broadcastData.transactions.find(tx => tx.contractName === 'ClaimTopicsRegistry')?.contractAddress,
  IdentityRegistryStorage: broadcastData.transactions.find(tx => tx.contractName === 'IdentityRegistryStorage')?.contractAddress,
  TrustedIssuersRegistry: broadcastData.transactions.find(tx => tx.contractName === 'TrustedIssuersRegistry')?.contractAddress
};

// Salva os endereços em um arquivo
const outputPath = path.join(__dirname, '../.contracts-addresses.json');
fs.writeFileSync(outputPath, JSON.stringify(addresses, null, 2));

console.log('✅ Endereços dos contratos salvos em:', outputPath);
console.log('📄 Endereços:', addresses); 