const { ethers } = require('ethers')
const fs = require('fs')
const path = require('path')

// If you don't specify a //url//, Ethers connects to the default 
// (i.e. ``http:/\/localhost:8545``)
const provider = new ethers.providers.JsonRpcProvider();

// The provider also allows signing transactions to
// send ether and pay to change state within the blockchain.
// For this, we need the account signer...
const signer = provider.getSigner()
const wallet = new ethers.Wallet('dc0a8af4787e8a4712326ff7d01bac6cb7b2879ef89bab088859860916c24482', provider);


const COMPILED_MARKET_PATH = path.join(__dirname, '../../bin/src/contracts/market/')
const marketFactoryABI = JSON.parse(fs.readFileSync(COMPILED_MARKET_PATH + 'MarketFactory.abi'));
console.log('Creating market factory contract instance...')
const marketFactoryContractInstance = new ethers.Contract('0x8C83ae3F369AF1cfc6aC8Cf956dC3567AeA11341', marketFactoryABI, signer);
console.log(marketFactoryContractInstance.deployTransaction)

console.log('Creating markets...')
createDummyMarkets()

async function createDummyMarkets() {
   await marketFactoryContractInstance.createMarket('Market DEFAULT_E', 0);
    await marketFactoryContractInstance.createMarket('Market DEFAULT_B', 0);
   await marketFactoryContractInstance.createMarket('Market DEFAULT_C', 0);
   await marketFactoryContractInstance.createMarket('Market SPECIFIC_D', 1);
}
