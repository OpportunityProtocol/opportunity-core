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

const DUMMY_MARKETS = [
    'DUMMY_MARKET1', //
    'DUMMY_MARKET2', //
    'DUMMY_MARKET3' //
]
const COMPILED_MARKET_PATH = path.join(__dirname, '../../bin/src/contracts/market/')
let marketFactoryABI = JSON.parse(fs.readFileSync(COMPILED_MARKET_PATH + 'MarketFactory.abi'));

console.log('Creating market factory contract instance...')
const marketFactoryContractInstance = new ethers.Contract('0x19971ee2D3AF28A23AcA9275270D730F6B3cd58d', marketFactoryABI, signer);

console.log('Creating market...')
waitExec()

async function waitExec() {
   await marketFactoryContractInstance.createMarket('Market DEFAULT_A', 0);
   await marketFactoryContractInstance.createMarket('Market DEFAULT_B', 0);
   await marketFactoryContractInstance.createMarket('Market DEFAULT_C', 0);
   await marketFactoryContractInstance.createMarket('Market SPECIFIC_D', 1);
}
