const HDWalletProvider = require('truffle-hdwallet-provider');
const Web3 = require('web3');

const provider = new HDWalletProvider(
	'mnemonic bird rat sink follow here dog but justice free service nation',
	'127.0.0.1:8545'
);

const web3 = new Web3(provider);

const compiledContract = require('../build/MyContractA.json');

(async () => {
	const accounts = await web3.eth.getAccounts();

	console.log(`Attempting to deploy from account: ${accounts[0]}`);

	const deployedContract = await new web3.eth.Contract(compiledContract.abi)
		.deploy({
			data: '0x' + compiledContract.evm.bytecode.object,
			arguments: [3, 5]
		})
		.send({
			from: accounts[0],
			gas: '2000000'
		});

	console.log(
		`Contract deployed at address: ${deployedContract.options.address}`
	);

	provider.engine.stop();
})();