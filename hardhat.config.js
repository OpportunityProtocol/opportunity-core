/**
 * @type import('hardhat/config').HardhatUserConfig
 */
 require('@nomiclabs/hardhat-waffle');
 require('@nomiclabs/hardhat-web3');
 require('@nomiclabs/hardhat-ethers');
 require('@openzeppelin/hardhat-upgrades');
 
 const ethers = require('ethers');
const { CHAIN_ID } = require('./config');

const providerUrl = "https://eth-rinkeby.alchemyapi.io/v2/_Z0mhNCo6N0S7ewye1pRUxJgdB1iY2gC" //process.env.MAINNET_PROVIDER_URL;
const developmentMnemonic = process.env.DEV_ETH_MNEMONIC;
console.log(developmentMnemonic)

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
  defaultNetwork: 'hardhat',
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
    ganache: {
      defaultBalanceEther: 10,
      url: providerUrl,
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
