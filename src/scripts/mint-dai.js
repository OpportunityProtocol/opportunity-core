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

//const DAI_CONTRACT = new ethers.Contract('', require('../test/build/contracts/test'))