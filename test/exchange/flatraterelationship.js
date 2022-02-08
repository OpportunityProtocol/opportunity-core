const { expect } = require("chai")
const { ethers } = require("hardhat");
const { CHAIN_ID } = require("../../config");

const amounts = {
	// 'aave': 25,
	// 'bat': 100,
	// 'comp': 25,
	'dai': 100,
	// 'link': 25,
	// 'mkr': 2,
	// 'sushi': 25,
	//'uni': 10,
	//'usdc': 100,
	// 'usdt': 100,
	// 'wbtc': 2,
	// 'yfi': 2,
	// 'zrx': 100
  };

async function mintTestDai() {
	// Seed first account with ERC-20 tokens on localhost
	try {
	const assetsToSeed = Object.keys(amounts)
	const seedRequests = []
	assetsToSeed.forEach((asset) => { seedRequests.push(seed(asset.toUpperCase(), amounts[asset])) })
	await Promise.all(seedRequests)
	console.log('\nReady to test locally! To exit, hold Ctrl+C.\n');
	} catch(error) {
	  console.log(error)
	}
  }
  
  // Moves tokens from cToken contracts to the localhost address
  // but this will work with any Ethereum address with a lot of tokens
  async function seed(asset, amount) {
	try {
	  provider = new hre.ethers.providers.JsonRpcProvider();
	  const accounts = await provider.listAccounts()
  
	  for (let i = 0; i < accounts.length; i++) {
  
		const cTokenAddress = Compound.util.getAddress('c' + asset, NETWORK);
  
		// Impersonate this address (only works in local testnet)
		console.log('Impersonating address on localhost... ', Compound.util.getAddress('c' + asset, NETWORK))
		await hre.network.provider.request({
		  method: 'hardhat_impersonateAccount',
		  params: [ cTokenAddress ],
		});
	  
		// Number of underlying tokens to mint, scaled up so it is an integer
		const numbTokensToSeed = (amount * Math.pow(10, Compound.decimals[asset])).toString()
	  
		const signer = provider.getSigner(cTokenAddress)
  
		const gasPrice = '0'; // only works in the localhost dev environment
		// const gasPrice = await provider.getGasPrice();
		const transferTrx = await Compound.eth.trx(
		  Compound.util.getAddress(asset, NETWORK),
		  'function transfer(address, uint256) public returns (bool)',
		  [ accounts[i], numbTokensToSeed ],
		  { provider: signer, gasPrice }
		);
		await transferTrx.wait(1)
	  
		const balanceOf = await Compound.eth.read(
		  Compound.util.getAddress(asset, NETWORK),
		  'function balanceOf(address) public returns (uint256)',
		  [ accounts[i] ],
		  { provider }
		);
	  
		const tokens = +balanceOf / Math.pow(10, Compound.decimals[asset])
		console.log('account: ' + accounts[i] + '::::' + asset + ' amount in first localhost account wallet:', tokens)
	  }
  
  
  
	} catch(error) {
	  console.log(error)
	}
  }

describe("Opportunity Relationship Functions", () => {
	let MarketFactoryContract,
		marketFactoryInstance,
		MarketContract,
		marketInstance,
		FlatRateRelationshipContract,
		flatRateRelationshipInstance,
		RelationshipContractEscrow,
		relationshipEscrowInstance;

	let marketAddress, marketCreator, marketName;

	let relationshipOwnerAddress, relationshipAddress, relationshipMarketAddress;


	beforeEach(async () => {
		const signers = await ethers.getSigners();
		employer = signers[0];

		worker = signers[1];
		sneakyEmployer = signers[2];
		sneakyWorker = signers[3];

		DaiContract = await ethers.getContractFactory('TestDai')
		daiContractInstance = await DaiContract.deploy(CHAIN_ID)

		for (const signer of signers) { 
			console.log('Minting dai: ' + signer.address)
			await daiContractInstance.mint(signer.address, 1000) 
			console.log(await daiContractInstance.balanceOf(signer.address))
		}

		MarketFactoryContract = await ethers.getContractFactory("MarketFactory");
		marketFactoryInstance = await MarketFactoryContract.deploy();

		RelationshipContractEscrow = await ethers.getContractFactory("RelationshipEscrow");

		relationshipEscrowInstance = await RelationshipContractEscrow.deploy(
			daiContractInstance.address,
			daiContractInstance.address
		);

		Market = await ethers.getContractFactory("Market");

		const marketCreateTxA = await marketFactoryInstance.createMarket("MarketA");

		const marketCreateTxAReceipt = await marketCreateTxA.wait();

		const marketCreateATxEvents = marketCreateTxAReceipt.events.find(
			(event) => event.event == "MarketCreated"
		);
		let [marketAddress, numCreatedMarkets, marketCreator, marketName] =
			marketCreateATxEvents.args;

		marketAddress = marketAddress;
		(marketCreator = marketCreator), (marketName = marketName);
		marketInstance = await ethers.getContractAt(
			"Market",
			marketAddress,
			employer
		); // await new ethers.Contract(marketAddress, marketAbi, ownerWallet)
			
		//mintTestDai()
	});

	it("happy path - should complete a flat rate relationship and transfer coins to worker", async () => {

		daiContractInstance.connect(employer).approve(daiContractInstance.address ,100)
		const relationshipCreateTx = await marketInstance.createFlatRateJob(
			daiContractInstance.address,
			relationshipEscrowInstance.address,
			"Is8J2o3kd7"
		);
		const relationshipCreateTxReceipt = await relationshipCreateTx.wait();
		const relationshipCreateTxEvents = relationshipCreateTxReceipt.events.find(
			(event) => event.event == "RelationshipCreated"
		);

		let [owner, relationship, marketAddressA] = relationshipCreateTxEvents.args;
		relationshipOwnerAddress = await employer.getAddress();
		relationshipMarketAddress = marketAddressA;
		relationshipAddress = relationship;

		const relationshipContractInstanceEmployer = await ethers.getContractAt(
			"FlatRateRelationship",
			relationshipAddress,
			employer
		);
    
    //await new ethers.Contract(relationshipAddress, relationshipAbi, ownerWallet)
		const relationshipContractInstanceWorker = await ethers.getContractAt(
			"FlatRateRelationship",
			relationshipAddress,
			worker
		); //await new ethers.Contract(relationshipAddress, relationshipAbi, workerWallet)

		const tx = await relationshipContractInstanceEmployer.assignNewWorker(worker.address, 100, "")
		 const txReceipt = await tx.wait()
		console.log(txReceipt)
	});
});
