const { ethers } = require('ethers')
const fs = require('fs')
const path = require('path')

function getPrivateKeysFromMnemonic(mnemonic, numberOfPrivateKeys = 20) {
   const result = [];
   for (let i = 0; i < numberOfPrivateKeys; i++) {
     result.push(ethers.Wallet.fromMnemonic(mnemonic, `m/44'/60'/0'/0/${i}`).privateKey);
   }
 }


const provider = new ethers.providers.JsonRpcProvider();
const signer = provider.getSigner()

const privateKey = getPrivateKeysFromMnemonic(process.env.DEV_ETH_MNEMONIC)
const wallet = new ethers.Wallet(privateKey[0])
console.log('Created wallet...')
console.log(wallet)


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
