const fs = require("fs");
const solc = require('solc')
const Web3 = require('web3');
const path = require('path')
const { ethers } = require('ethers')

// If you don't specify a //url//, Ethers connects to the default 
// (i.e. ``http:/\/localhost:8545``)
const provider = new ethers.providers.JsonRpcProvider();

// The provider also allows signing transactions to
// send ether and pay to change state within the blockchain.
// For this, we need the account signer...
const signer = provider.getSigner()

const wallet = new ethers.Wallet('02c0408f9e4ba98194f3986071eeccea049ebc967d4ddb831562af8cbad2a860', provider);


(async function doWork() {
	const COMPILED_MARKET_PATH = path.join(__dirname, '../../bin/src/contracts/market/')
	const COMPILED_LIBRARIES_PATH = path.join(__dirname, '../../bin/src/contracts/libraries/')
	
	const contractSources = [
		{
			name: 'MarketFactory',
			abi: COMPILED_MARKET_PATH + "MarketFactory.abi",
			bytecode: COMPILED_MARKET_PATH + "MarketFactory.bin"
		},
		{
			name: 'Evaluation',
			abi: COMPILED_LIBRARIES_PATH + "Evaluation.abi",
			bytecode: COMPILED_LIBRARIES_PATH + "Evaluation.bin"
		},
		{	
			name: 'MarketLib',
			abi: COMPILED_LIBRARIES_PATH + "MarketLib.abi",
			bytecode: COMPILED_LIBRARIES_PATH + "MarketLib.bin"
		},
		{
			name: 'StringUtils',
			abi: COMPILED_LIBRARIES_PATH + "StringUtils.abi",
			bytecode: COMPILED_LIBRARIES_PATH + "StringUtils.bin"
		}
	]
	
		let i = 0;
		let abi = JSON.parse(fs.readFileSync(contractSources[i]['abi']));
		let bytecode = '0x' + fs.readFileSync(contractSources[i]['bytecode']).toString();
		const factory = new ethers.ContractFactory(abi, bytecode, wallet);

		// If your contract requires constructor args, you can specify them here
		const contract = await factory.deploy();
}());


//compile - change data in servce - re install service - create market script - deploy 5 markets