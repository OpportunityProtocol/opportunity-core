/**
 * @type import('hardhat/config').HardhatUserConfig
 */
 require('@nomiclabs/hardhat-waffle');
 require('@nomiclabs/hardhat-web3');
 require('@nomiclabs/hardhat-ethers');
 require('@openzeppelin/hardhat-upgrades');
 
 const ethers = require('ethers');
const { CHAIN_ID } = require('./config');

const providerUrl = process.env.MAINNET_PROVIDER_URL;
const developmentMnemonic = process.env.DEV_ETH_MNEMONIC;

console.log(providerUrl)
if (!providerUrl) {
  console.error('Missing JSON RPC provider URL as environment variable `MAINNET_PROVIDER_URL`\n');
  process.exit(1);
}

if (!developmentMnemonic) {
  console.error('Missing development Ethereum account mnemonic as environment variable `DEV_ETH_MNEMONIC`\n');
  process.exit(1);
}

module.exports = {
  solidity: {
    version: '0.8.7',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      },
  },
  },
  networks: {
    hardhat: {
      forking: {
        url: providerUrl,
        accounts: {
          mnemonic: developmentMnemonic
        },
        chainId: CHAIN_ID
      },
      gasPrice: 0,
      initialBaseFeePerGas: 0,
      accounts: {
        mnemonic: developmentMnemonic,
      },
      chainId: CHAIN_ID
    },
    localhost: {
      chainId: CHAIN_ID,
      forking: {
        url: providerUrl,
        accounts: {
          mnemonic: developmentMnemonic
        }
      },
      gasPrice: 0,
      initialBaseFeePerGas: 0,
    }
  }
};
