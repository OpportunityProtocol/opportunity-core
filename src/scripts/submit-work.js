
const Moralis = require('moralis')
const IPFS = require('ipfs-api')
const fs = require('fs')
const path = require('path')
const { ethers } = require('ethers')
const Web3 = require('web3')

const relationshipAddress = '0xF43bD7B854c19588dE533864CCE948E61D56ead2'

const provider = new ethers.providers.JsonRpcProvider('http://localhost:8545', "any");
const wallet = new ethers.Wallet('f4bdfbd7d59eef69cb569ce2200d8c23193a0a92e928ac1b08fe92ef77d41c25', provider)

const COMPILED_RELATIONSHIP_PATH = path.join(__dirname, '../../bin/src/contracts/exchange/')
const workRelationshipABI = JSON.parse(fs.readFileSync(COMPILED_RELATIONSHIP_PATH + 'WorkRelationship.abi'));

const COMPILED_EXCHANGE_PATH = path.join(__dirname, '../../bin/src/contracts/exchange/')
const workExchangeABI = JSON.parse(fs.readFileSync(COMPILED_EXCHANGE_PATH + 'WorkExchange.abi'));

let web3Instance, workExchangeAddress, globalSolutionLink, checkedContractSolutionPointer
const workRelationshipContractInstance = new ethers.Contract(relationshipAddress, workRelationshipABI, provider).connect(wallet)
execute()

const signSubmission = async () => {

  const message = {
      _submission: globalSolutionLink,
    };

    const typedData = JSON.stringify({
      "types": {
        "EIP712Domain": [
          {
            "name": "name",
            "type": "string",
          },
          {
            "name": "version",
            "type": "string",
          },
          {
            "name": "chainId",
            "type": "uint256",
          },
          {
            "name": "verifyingContract",
            "type": "address",
          },
        ],
        "Submit": [
          {
            "name": "_submission",
            "type": "bytes32",
          },
        ],
      },
      "primaryType": "Submit",
      "domain": {
        "name": "Dai Escrow",
        "version": "1",
        "chainId": 1337,
        "verifyingContract": workExchangeAddress
      },
      "message": message
    });

    const from = '0x74F6ff3Ae3f5EB38354FfB05867a37B7B40E6000'
    const params = [from, typedData];
    const method = 'eth_signTypedData_v3';

  await web3Instance.currentProvider.sendAsync({
    id: 1,
    method,
    params,
    from,
  }, function(error, result) {
    if (error) throw error;
      const r = result.result.slice(0, 66);
      const s = '0x' + result.result.slice(66, 130);
      const v = Number('0x' + result.result.slice(130, 132))
      resolve({
        v,
        r,
        s,
      });
  });
  
  console.log('Returning signature form signSubmission()...')
}

async function execute() {
    await setup()
    await initUser()
    //await submitSolutionToIpfs()
    //await executeSmartContract()
    await checkWorkSolutionLink()
    //await terminateProcess()
}

async function setup() {
    await workRelationshipContractInstance.functions.workExchange().then(value => {
        workExchangeAddress = value
    })
}

async function initUser() {
    try {
    //const user = await Moralis.authenticate({ chainId: 1337 })
    //const web3 = await Moralis.Web3.enable()

    const provider = new ethers.providers.JsonRpcProvider("http://localhost:8545", "any");
    const wallet = new ethers.Wallet('f4bdfbd7d59eef69cb569ce2200d8c23193a0a92e928ac1b08fe92ef77d41c25', provider);

    web3Instance = await new Web3(new Web3.providers.HttpProvider('http://localhost:8545'))
    console.log('Web3 Instance Set')
    //console.log(web3Instance)
    } catch(error) {
        console.log(error)
    }
}

async function submitSolutionToIpfs() {
    const ipfs = new IPFS({ host: 'ipfs.infura.io', 
    port: 5001,protocol: 'https' });

    console.log('Reading file content..')
    await fs.readFile(path.join(__dirname, './data/file.txt').toString(), 'utf8', async function(err, data){
        console.log('File content: ' + data);

        console.log('Adding file to IPFS')
        await ipfs.add(Buffer.from(data), (err, hash) => {
            globalSolutionLink = hash[0].hash
            console.log('globalSolutionLink set to: ' + globalSolutionLink)
        })
    });
}

async function executeSmartContract() {
    const {v,r,s} = await signSubmission()
    console.log('Message signed with values: ')
    console.log('V: ' + v)
    console.log('R: ' + r)
    console.log('S: ' + s)

    await workRelationshipContractInstance.submitWork(globalSolutionLink)
    console.log('Work submitted to smart contract')
}

async function checkWorkSolutionLink() {
    console.log('Checking work solution link in smart contract')
    await workRelationshipContractInstance.functions.getTaskSolutionPointer().then(value => {
        checkedContractSolutionPointer = value
    })

    console.log('The value for the pointer in the smart contract is: ' + checkedContractSolutionPointer)
}

function terminateProcess() {
    console.log('Logging user out...')
    Moralis.User.logOut()
    console.log('Process finished..')
}