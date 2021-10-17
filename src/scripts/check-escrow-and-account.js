const { ethers } = require('ethers')
const fs = require('fs')
const path = require('path')
// If you don't specify a //url//, Ethers connects to the default 
// (i.e. ``http:/\/localhost:8545``)
const provider = new ethers.providers.JsonRpcProvider('http://localhost:8545', "any");
const signer = provider.getSigner('0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1')

const wallet = new ethers.Wallet('0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d', provider)

const relationshipAddress = "0xA72B5C5493d87dfef6ddd5F22079F49596E53eF6"
const daiAddress = '0xd1453fE9F27f459B32204c502F842b63EFaAAf07'


// The provider also allows signing transactions to
// send ether and pay to change state within the blockchain.
// For this, we need the account signer...

const COMPILED_RELATIONSHIP_PATH = path.join(__dirname, '../../bin/src/contracts/exchange/')
const workRelationshipABI = JSON.parse(fs.readFileSync(COMPILED_RELATIONSHIP_PATH + 'WorkRelationship.abi'));

const COMPILED_EXCHANGE_PATH = path.join(__dirname, '../../bin/src/contracts/exchange/')
const workExchangeABI = JSON.parse(fs.readFileSync(COMPILED_EXCHANGE_PATH + 'WorkExchange.abi'));


const COMPILED_DAI_PATH = path.join(__dirname, '../../bin/src/contracts/test/')
const daiABI = JSON.parse(fs.readFileSync(COMPILED_DAI_PATH + 'Dai.abi'));

console.log('Checking contracts')
checkRelationshipStatus()

async function checkRelationshipStatus() {
    const daiContractInstance = new ethers.Contract(daiAddress.toString(), daiABI, provider).connect(wallet)
    console.log('Checking the balance of the account: ' + '0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1...')
    const accountBalance = await daiContractInstance.functions.balanceOf('0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1')
    console.log('The balance of the account is: ' + accountBalance)


    const workRelationshipContractInstance = new ethers.Contract(relationshipAddress, workRelationshipABI).connect(wallet)

    console.log('Checking the worker and owner of the work relationship contract...')

    let owner
    await workRelationshipContractInstance.functions.owner().then(value => {
        owner = value;
    })


    let worker
    await workRelationshipContractInstance.functions.worker().then(value => {
        worker = value
    })

    console.log('Owner address: ' + owner)
    console.log('Worker: ' + worker)

    console.log('Checking the address of the work exchange contract...')
    let workExchangeContractAddress
    await workRelationshipContractInstance.functions.workExchange().then(value => {
        workExchangeContractAddress = value
    })
    console.log('Work Exchange Address: ' + workExchangeContractAddress)

    console.log('Checking the work relationship contract status and payout...')
    let contractStatus
    await workRelationshipContractInstance.functions._contractStatus().then(value => {
        contractStatus = value
    })

    let contractPayout
    await workRelationshipContractInstance.functions.contractPayout().then(value => {
        contractPayout = value
    })
    console.log('Contract Status: ' + contractStatus)
    console.log('Contract Payout: ' + contractPayout)



    const workExchangeContractInstance = new ethers.Contract(workExchangeContractAddress.toString(), workExchangeABI, provider).connect(wallet)
    let escrowStatus = 0

    await workExchangeContractInstance.functions.status().then(value => {
        escrowStatus = value
    })
    console.log('Escrow Status: ' + escrowStatus)

    let exchangePayout
    await workExchangeContractInstance.functions.wad().then(value => {
        exchangePayout = value
    })
    console.log('The payout in work exchange is: ' + exchangePayout)
    
    let beneficiary = '', depositor = ''
    await workExchangeContractInstance.functions.beneficiary().then(value => {
        beneficiary = value
    })

    await workExchangeContractInstance.functions.depositor().then(value => {
        depositor = value
    })

    console.log('Beneficiary: ' + beneficiary)
    console.log('Depositor: ' + depositor)



    console.log('Checking DaiEscrow balance..')
   let daiBalanceFromRelationship
   await daiContractInstance.functions.balanceOf(workExchangeContractAddress.toString()).then(value => {
       daiBalanceFromRelationship = value
   })
    console.log('Dai Escrow Address Balance From Relationship: ' + daiBalanceFromRelationship)

    let taskMetadataPointer = ''
    let taskSolutionPointer = ''
    console.log('Checking submission value')
    await workRelationshipContractInstance.functions._taskMetadataPointer().then(value => {
        taskMetadataPointer = value
    })

    await workRelationshipContractInstance.getTaskSolutionPointer().then(value => {
        taskSolutionPointer = value
    })

    console.log('Metadata Pointer: ' + taskMetadataPointer)
    console.log('Task solution pointer: ' + taskSolutionPointer)
}
