const ethers = require('ethers')
const path = require('path')
const fs = require('fs')

function runDispute() {
    const provider = new ethers.providers.JsonRpcProvider()
    const signer = provider.getSigner()
    const disputeInterface = require('../artifacts/contracts/dispute/Dispute.sol/Dispute.json')

    const disputeAbi = disputeInterface.abi
    const disputeBytecode = disputeInterface.bytecode
    const contractFactory = new ethers.ContractFactory(abi, bytecode, signer)

    const ipfsComplaintHash = ''
    const otherIpfsComplaintHash = ''
    const disputeContract = await contractFactory.deploy('0x', );
    const contractAddress = disputeContract.address

    const tokenAddress = ''


}

runDispute()