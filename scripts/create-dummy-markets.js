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
const wallet = new ethers.Wallet('f4bdfbd7d59eef69cb569ce2200d8c23193a0a92e928ac1b08fe92ef77d41c25', provider);


const COMPILED_MARKET_PATH = path.join(__dirname, '../bin/contracts/market/')
const marketFactoryABI = JSON.parse(fs.readFileSync(COMPILED_MARKET_PATH + 'MarketFactory.abi'));

console.log('Creating market factory contract instance...')
const marketFactoryContractInstance = new ethers.Contract('0x8eb065482F681537e90eab826540E9DF8D8cBd89', marketFactoryABI, signer);
console.log('Creating markets...')
createDummyMarkets()

async function createDummyMarkets() {
   try {
   await marketFactoryContractInstance.createMarket('Dummy Market One', 0);
   await marketFactoryContractInstance.createMarket('Dummy Market Two', 0);
   await marketFactoryContractInstance.createMarket('Dummy Market Three', 0);
   await marketFactoryContractInstance.createMarket('Dummy Market Four', 0);
   await marketFactoryContractInstance.createMarket('Dummy Market Five', 0);
   }catch(error) {
      console.log(error)
   }
}
