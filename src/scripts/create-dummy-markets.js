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
const wallet = new ethers.Wallet('02c0408f9e4ba98194f3986071eeccea049ebc967d4ddb831562af8cbad2a860', provider);

const COMPILED_MARKET_PATH = path.join(__dirname, '../../bin/src/contracts/market/')
const marketFactoryABI = JSON.parse(fs.readFileSync(COMPILED_MARKET_PATH + 'MarketFactory.abi'));
console.log('Creating market factory contract instance...')
const marketFactoryContractInstance = new ethers.Contract('0x6A11FB059fbcf8E2789a8dcaFa303D75D5E41300', marketFactoryABI, signer);
console.log(marketFactoryContractInstance.deployTransaction.wait())

console.log('Creating markets...')
//createDummyMarkets()

async function createDummyMarkets() {
 //  await marketFactoryContractInstance.createMarket('Market DEFAULT_E', 0);

   /*await marketFactoryContractInstance.createMarket('Market DEFAULT_B', 0);
   await marketFactoryContractInstance.createMarket('Market DEFAULT_C', 0);
   await marketFactoryContractInstance.createMarket('Market SPECIFIC_D', 1);*/
}
