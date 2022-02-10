const { ethers } = require('ethers')
const fs = require('fs')
const path = require('path')

const provider = new ethers.providers.JsonRpcProvider();
const signer = provider.getSigner()


const COMPILED_MARKET_PATH = path.join(__dirname, '../bin/contracts/market/')
const marketFactoryABI = JSON.parse(fs.readFileSync(COMPILED_MARKET_PATH + 'MarketFactory.abi'));

console.log('Creating market factory contract instance...')
const marketFactoryContractInstance = new ethers.Contract('0xA31Ea4553E82e08b3F411B29C009ECd45AE1738B', marketFactoryABI, signer);
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
