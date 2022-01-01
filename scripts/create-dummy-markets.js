const { ethers } = require('ethers')
const fs = require('fs')
const path = require('path')

const provider = new ethers.providers.JsonRpcProvider();
const signer = provider.getSigner()

const wallet = new ethers.Wallet('0x6cbed15c793ce57650b9877cf6fa156fbef513c4e6134f022a85b1ffdd59b2a1')
console.log('Created wallet...')
console.log(wallet)


const COMPILED_MARKET_PATH = path.join(__dirname, '../bin/contracts/market/')
const marketFactoryABI = JSON.parse(fs.readFileSync(COMPILED_MARKET_PATH + 'MarketFactory.abi'));

console.log('Creating market factory contract instance...')
const marketFactoryContractInstance = new ethers.Contract('0x9fd244e5972F28e2F133bd3dAA5A6691C8E6d1c7', marketFactoryABI, signer);
console.log('Creating markets...')
createDummyMarkets()

async function createDummyMarkets() {
   try {
   await marketFactoryContractInstance.createMarket('Dummy Market One', 0)
   await marketFactoryContractInstance.createMarket('Dummy Market Two', 0);
   await marketFactoryContractInstance.createMarket('Dummy Market Three', 0);
   await marketFactoryContractInstance.createMarket('Dummy Market Four', 0);
   await marketFactoryContractInstance.createMarket('Dummy Market Five', 0);
   }catch(error) {
      console.log(error)
   }
}
