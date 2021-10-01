const { ethers } = require('ethers')
const fs = require('fs')
const path = require('path')
// If you don't specify a //url//, Ethers connects to the default 
// (i.e. ``http:/\/localhost:8545``)
const provider = new ethers.providers.JsonRpcProvider('http://localhost:8545', "any");
const signer = provider.getSigner('0x74F6ff3Ae3f5EB38354FfB05867a37B7B40E6000')

const wallet = new ethers.Wallet('f4bdfbd7d59eef69cb569ce2200d8c23193a0a92e928ac1b08fe92ef77d41c25', provider)

const relationshipAddress = '0xB0cD295606B20CC36dC6e7e2CC697606f8A1cf6E'
const daiAddress = '0x4aD26D864936Ac893EC98632D424bF4E8361926a'


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
    console.log('Checking the balance of the account: ' + '0x74F6ff3Ae3f5EB38354FfB05867a37B7B40E6000...')
    const accountBalance = await daiContractInstance.functions.balanceOf('0x74F6ff3Ae3f5EB38354FfB05867a37B7B40E6000')
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
    await workRelationshipContractInstance.functions.contractType().then(value => {
        contractStatus = value
    })

    let contractPayout
    await workRelationshipContractInstance.functions.contractPayout().then(value => {
        contractPayout = value
    })
    console.log('Contract Status: ' + contractStatus)
    console.log('Contract Payout: ' + contractPayout)


    const workExchangeContractInstance = new ethers.Contract(workExchangeContractAddress.toString(), workExchangeABI, provider).connect(wallet)

    let exchangePayout
    await workExchangeContractInstance.functions.wad().then(value => {
        exchangePayout = value
    })
    console.log('The payout in work exchange is: ' + exchangePayout)
    
    console.log('Checking DaiEscrow balance..')
   let daiBalanceFromRelationship
   await daiContractInstance.functions.balanceOf(workExchangeContractAddress.toString()).then(value => {
       daiBalanceFromRelationship = value
   })
    console.log('Dai Escrow Address Balance From Relationship: ' + daiBalanceFromRelationship)
}
