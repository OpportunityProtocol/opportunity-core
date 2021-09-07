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
const wallet = new ethers.Wallet('b64ffce83525dbca10c810abf1219eb671a9b1ee1d29f5cbac2fc52ac6344b78', provider);


const COMPILED_MARKET_PATH = path.join(__dirname, '../../bin/src/contracts/market/')
const marketFactoryABI = JSON.parse(fs.readFileSync(COMPILED_MARKET_PATH + 'MarketFactory.abi'));
console.log('Creating market factory contract instance...')
const marketFactoryContractInstance = new ethers.Contract('0x9AE94160Cb13404f30EBAd4266Bda653D7082634', marketFactoryABI, signer);

console.log('Creating markets...')
createDummyMarkets()

async function createDummyMarkets() {
   await marketFactoryContractInstance.createMarket('Market DEFAULT', 0);
}
