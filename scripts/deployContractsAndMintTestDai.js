const hre = require('hardhat');
const Compound = require('@compound-finance/compound-js');
const { TASK_NODE_CREATE_SERVER } = require('hardhat/builtin-tasks/task-names');
const { NETWORK, CHAIN_ID } = require('../config');
require("@nomiclabs/hardhat-ganache");
const jsonRpcUrl = 'http://localhost:8545'
let provider;

// Amount of tokens to seed in the 0th account on localhost
// Uncomment a line below to seed the account with that asset
// The amounts are limited by the current cToken asset balance
// You can do the same thing with any high-balance Ethereum account (whales)
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


async function main() {
  const jsonRpcServer = await hre.run(TASK_NODE_CREATE_SERVER, {
    hostname: 'localhost',
    port: 8545,
    provider: hre.network.provider,
  });

  await jsonRpcServer.listen();

  await hre.run('compile')
  await mintTestDai()
  await deployOpportunityContracts()
}

main()
  .then(() => {}/*process.exit(0)*/)
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

  async function deployOpportunityContracts() {
    const MarketFactory = await hre.ethers.getContractFactory("MarketFactory");
    const UserRegistration = await hre.ethers.getContractFactory('UserRegistration')
    const UserSummaryFactory = await hre.ethers.getContractFactory('UserSummaryFactory')
    const ParticipationToken = await hre.ethers.getContractFactory('ParticipationToken')
  
    console.log('Deploying market factory...')
    const marketFactory = await MarketFactory.deploy()
    console.log('Address: ' + marketFactory.address)

    console.log('Deploying UserSummaryFactory...')
    const userSummaryFactory = await UserSummaryFactory.deploy()
    console.log('Address: ' + userSummaryFactory.address)

    console.log('Deploying participation token...')
    const participationToken = await ParticipationToken.deploy('Participation', 'PTN', userSummaryFactory.address)
    console.log('Address: ' + participationToken.address)
    
    console.log('Deploying user registration...')
    const userRegistration = await UserRegistration.deploy(userSummaryFactory.address, participationToken.address)
    console.log('Address: ' + userRegistration.address)
  }
    
  
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
    provider = new hre.ethers.providers.JsonRpcProvider(jsonRpcUrl, { chainId: CHAIN_ID });
    console.log(provider)
    const accounts = await provider.listAccounts()
    console.log(accounts)

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
