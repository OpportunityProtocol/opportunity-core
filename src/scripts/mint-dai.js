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


const COMPILED_DAI_PATH = path.join(__dirname, '../../bin/src/contracts/test/')
const daiContractAbi = JSON.parse(fs.readFileSync(COMPILED_DAI_PATH + 'Dai.abi'));

console.log('Creating Dai contract instance...')
const daiContractInstance = new ethers.Contract('0x55Ab6543bC504E80e32C43384bc088c82814Cd5B', daiContractAbi, signer);
console.log('Minting Dai')
mintDai()

async function mintDai() {
    console.log('Minting dai to first address...')
    await daiContractInstance.mint('0x74F6ff3Ae3f5EB38354FfB05867a37B7B40E6000', 10000)
    console.log('Minting dai to second address...')
    await daiContractInstance.mint('0xd4342e1d818843f49cd25273d2fbea73d1719da6', 10000)
}
