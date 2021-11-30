const { ethers } = require('ethers')
const fs = require('fs')
const path = require('path')

const provider = new ethers.providers.JsonRpcProvider('http://localhost:8545', "any");
const signer = provider.getSigner('0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1')

const wallet = new ethers.Wallet('0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d', provider)

// The provider also allows signing transactions to
// send ether and pay to change state within the blockchain.
// For this, we need the account signer...
const address = '0xc4F1B570e57A5035a25035AFA5f7CbA204627024'
const abi = require('../artifacts/contracts/user/UserRegistration.sol/UserRegistration.json').abi

checkRelationshipStatus()

async function checkRelationshipStatus() {
    const contract = new ethers.Contract(address, abi, provider).connect(wallet)

    const userSummaryContractAddress = 
      await contract.getTrueIdentification('0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1');
    console.log(userSummaryContractAddress)

}
