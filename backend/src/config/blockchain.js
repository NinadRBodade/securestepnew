// Blockchain configuration for SOS event logging
// This is a stub implementation - will be connected to actual blockchain later

const provider = {
  name: 'ethereum-sepolia',
  rpcUrl: process.env.BLOCKCHAIN_RPC_URL || 'http://localhost:8545',
  chainId: 11155111
};

const wallet = {
  address: process.env.BLOCKCHAIN_WALLET_ADDRESS || '0x0000000000000000000000000000000000000000',
  privateKey: process.env.BLOCKCHAIN_PRIVATE_KEY || ''
};

// Contract configuration
const contract = {
  address: process.env.CONTRACT_ADDRESS || '0x0000000000000000000000000000000000000000',
  abi: [] // Will be populated when contract is deployed
};

module.exports = {
  provider,
  wallet,
  contract,
  enabled: process.env.BLOCKCHAIN_ENABLED === 'true' || false
};
