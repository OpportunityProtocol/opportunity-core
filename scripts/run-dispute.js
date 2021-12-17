const { ethers, utils} = require('ethers')
const path = require('path')
const fs = require('fs')
const assert = require('assert')
const Bluebird = require('bluebird')
const { EntityApi, VochainWaiter, VotingApi, VotingOracleApi } = require('@vocdoni/voting')
const { IGatewayClient, Erc20TokensApi, DVoteGateway, GatewayPool, IGatewayDiscoveryParameters } = require('@vocdoni/client')
const { EntityMetadata, EntityMetadataTemplate, INewProcessErc20Params, ProcessMetadata, ProcessMetadataTemplate } = require('@vocdoni/data-models')
const { CensusErc20Api } = require('@vocdoni/census')
const { ProcessContractParameters,
    ProcessEnvelopeType,
    ProcessMode} = require('@vocdoni/contract-wrappers')

    const abi = JSON.stringify([{"inputs":[{"internalType":"uint256","name":"chainId_","type":"uint256"}],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"src","type":"address"},{"indexed":true,"internalType":"address","name":"guy","type":"address"},{"indexed":false,"internalType":"uint256","name":"wad","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":true,"inputs":[{"indexed":true,"internalType":"bytes4","name":"sig","type":"bytes4"},{"indexed":true,"internalType":"address","name":"usr","type":"address"},{"indexed":true,"internalType":"bytes32","name":"arg1","type":"bytes32"},{"indexed":true,"internalType":"bytes32","name":"arg2","type":"bytes32"},{"indexed":false,"internalType":"bytes","name":"data","type":"bytes"}],"name":"LogNote","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"src","type":"address"},{"indexed":true,"internalType":"address","name":"dst","type":"address"},{"indexed":false,"internalType":"uint256","name":"wad","type":"uint256"}],"name":"Transfer","type":"event"},{"constant":true,"inputs":[],"name":"DOMAIN_SEPARATOR","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"PERMIT_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"usr","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"usr","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"burn","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"guy","type":"address"}],"name":"deny","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"usr","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"mint","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"src","type":"address"},{"internalType":"address","name":"dst","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"move","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"nonces","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"holder","type":"address"},{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"nonce","type":"uint256"},{"internalType":"uint256","name":"expiry","type":"uint256"},{"internalType":"bool","name":"allowed","type":"bool"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"permit","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"usr","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"pull","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"usr","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"push","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"guy","type":"address"}],"name":"rely","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"dst","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"src","type":"address"},{"internalType":"address","name":"dst","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"version","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"wards","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"}])
const daiABI = JSON.parse(abi);


const tokenAddress = '0x5592ec0cfb4dbc12d3ab100b257153436a1f0fea'


async function connectGateways(){
    console.log("Connecting to the gateways")
    const options  = {
        networkId: 'rinkeby',
        environment: 'dev',
        bootnodesContentUri: 'https://bootnodes.vocdoni.net/gateways.dev.json',
        //numberOfGateways: 2,
        // timeout: 10000,
    }
    const pool = await GatewayPool.discover(options)

    console.log(pool)
    console.log('@@@@@@@@@@@@@@@@@@@@@@@@@@@')

    console.log("Connected to", pool.dvoteUri)
    console.log("Connected to", pool.provider["connection"].url)

    return pool
}

async function getOracleClient() {
    const oracleClient = new DVoteGateway({
        uri: 'https://signaling-oracle.dev.vocdoni.net/dvote',
        supportedApis: ["oracle"]
    })
    await oracleClient.init()

    return oracleClient
}

async function ensureEntityMetadata(entityWallet, gwPool) {
    console.log('OOOOOOOOOOOOOOO')

   /* const daiContract = new ethers.Contract(tokenAddress, daiABI)
    daiContract.functions.balanceOf('0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1').then(val => {
        console.log('balance: ' + val)
    })*/

   /* if ((await entityWallet.getBalance()).eq(0)) {
        console.log('OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO')
        throw new Error("The account has no ether")
    } else {
        console.log('OSOSOSOSOSOSOSOSSO')
    }*/

    //const meta = await EntityApi.getMetadata(entityWallet.address, gwPool).catch(err => console.log(err))
    //sif (!!meta) return // already present

    console.log("Setting Metadata for entity", entityWallet.address)

    const metadata = JSON.parse(JSON.stringify(EntityMetadataTemplate))
console.log('meta')
    metadata.name = { default: "Test Organization Name" }
    metadata.description = { default: "Description of the test organization goes here" }
    metadata.media = {
        avatar: "www.google.com/hi",
        header: "Hello",
        logo: "logo"
    }
    console.log('set')

    await EntityApi.setMetadata(entityWallet.address, metadata, entityWallet, gwPool)
    console.log("Metadata updated")

    // Read back
    const entityMetaPost = await EntityApi.getMetadata(entityWallet.address, gwPool)

    //assert(entityMetaPost)
    //assert.strictEqual(entityMetaPost.name.default, metadata.name.default)
    //assert.strictEqual(entityMetaPost.description.default, metadata.description.default)

    return entityMetaPost
}

async function waitUntilPresent(processId, gwPool) {
    //assert(gwPool)
   //assert(processId)

    let attempts = 6
    while (attempts >= 0) {
        console.log("Waiting for process", processId, "to be created")
        await VochainWaiter.wait(1, gwPool)

        const state = await VotingApi.getProcessState(processId, gwPool).catch(() => null)
        if (state?.entityId) break

        attempts--
    }
    if (attempts < 0) throw new Error("The process still does not exist on the Vochain")
}

async function waitUntilStarted(processId, startBlock, gwPool) {
    //assert(gwPool)
    //assert(processId)
    console.log('waitUntilStarted')

    // start block
    await VochainWaiter.waitUntil(startBlock, gwPool, { verbose: true })

    console.log("Waiting for the process to be ready")
    const state = await VotingApi.getProcessState(processId, gwPool)

    //assert.strictEqual(state.status, ProcessStatus.READY, "Should be ready but is not")
}

async function launchNewVote(creatorWallet, gwPool) {

    // TOKEN CONTRACT

    if (!await Erc20TokensApi.isRegistered(tokenAddress, gwPool)) {
        await CensusErc20Api.registerTokenAuto(
            tokenAddress,
            creatorWallet,
            gwPool
        )

        assert(await Erc20TokensApi.isRegistered(tokenAddress, gwPool))
    }

    const sourceBlockHeight = (await gwPool.provider.getBlockNumber()) - 1
    const tokenInfo = await CensusErc20Api.getTokenInfo(tokenAddress, gwPool)
    const proof = await CensusErc20Api.generateProof(tokenAddress, creatorWallet.address, tokenInfo.balanceMappingPosition, sourceBlockHeight, gwPool.provider)
    if (!proof?.storageProof?.length)
        throw new Error("Invalid storage proof")

    // METADATA

    console.log("Preparing the new vote metadata")

    const processMetadataPre = JSON.parse(JSON.stringify(ProcessMetadataTemplate)) // make a copy of the template
    processMetadataPre.title.default = "E2E process"
    processMetadataPre.description.default = "E2E process"
    processMetadataPre.questions = [
        {
            title: { default: "The title of the first question" },
            description: { default: "The description of the first question" },
            choices: [
                { title: { default: "Yes" }, value: 0 },
                { title: { default: "No" }, value: 1 },
            ]
        }
    ]
    const maxValue = processMetadataPre.questions.reduce((prev, cur) => {
        const localMax = cur.choices.reduce((prev, cur) => prev > cur.value ? prev : cur.value, 0)
        return localMax > prev ? localMax : prev
    }, 0)

    // BLOCK

    console.log("Getting the block height")
    const currentBlock = await VotingApi.getBlockHeight(gwPool)
    const startBlock = currentBlock + 15
    const blockCount = 6 * 4 // 4m

    const processParamsPre = {
        mode: ProcessMode.make({ autoStart: true }),
        envelopeType: ProcessEnvelopeType.make({}), // bit mask
        metadata: processMetadataPre,
        startBlock,
        blockCount,
        maxCount: 1,
        maxValue,
        maxTotalCost: 0,
        costExponent: 10000,  // 1.0000
        maxVoteOverwrites: 1,
        sourceBlockHeight,
        tokenAddress: tokenAddress,
        paramsSignature: "0x0000000000000000000000000000000000000000000000000000000000000000"
    }

    const tokenDetails = {
        balanceMappingPosition: tokenInfo.balanceMappingPosition,
        storageHash: proof.storageHash,
        storageProof: {
            key: proof.storageProof[0].key,
            value: proof.storageProof[0].value,
            proof: proof.storageProof[0].proof
        }
    }

    // Connect to the oracle
    const oracleClient = await getOracleClient()

    console.log("Creating the process")
    const processId = await VotingOracleApi.newProcessErc20(processParamsPre, tokenDetails, creatorWallet, gwPool, oracleClient)
    assert(processId)
    console.log("Created the process", processId)

    await waitUntilPresent(processId, gwPool)
console.log('213')
    // Reading back

    const processParams = await VotingApi.getProcessState(processId, gwPool)
    console.log('216')
    /*assert.strictEqual(processParams.entityAddress.toLowerCase(), creatorWallet.address.toLowerCase())
    assert.strictEqual(processParams.startBlock, processParamsPre.startBlock, "SENT " + JSON.stringify(processParamsPre) + " GOT " + JSON.stringify(processParams))
    assert.strictEqual(processParams.blockCount, processParamsPre.blockCount)
    assert.strictEqual(processParams.censusUri, processParamsPre.censusUri)*/
console.log('221')
    const processMetadata = await VotingApi.getProcessMetadata(processId, gwPool)
    console.log(processMetadata)

    return { processId, processParams, processMetadata }
}

////////////////////////////////


function getChoicesForVoter(questionCount, voterIdx) {
    const indexes = new Array(questionCount).fill(0).map((_, i) => i)
    const votesPattern = 'all-0'
    return indexes.map((_, idx) => {
        switch (votesPattern) {
            case "all-0": return 0
            case "all-1": return 1
            case "all-2": return 2
            case "all-even": return (voterIdx % 2 == 0) ? 0 : 1
            case "incremental": return idx
            default: return 0
        }
    })
}

async function submitVotes(processId, processParams, processMetadata, accounts, gwPool) {
    console.log("Launching votes")

    const processKeys = processParams.envelopeType.hasEncryptedVotes ? await VotingApi.getProcessKeys(processId, gwPool) : null
    const balanceMappingPosition = (await CensusErc20Api.getTokenInfo(tokenAddress, gwPool)).balanceMappingPosition

    await Bluebird.map(accounts, async (account, idx) => {

        // VOTER
        const wallet = new ethers.Wallet(account.privateKey)

        const result = await CensusErc20Api.generateProof(tokenAddress, wallet.address, balanceMappingPosition, processParams.sourceBlockHeight, gwPool.provider)

        const choices = getChoicesForVoter(processMetadata.questions.length, idx)
        const censusProof = result.storageProof[0]

        const envelope = processParams.envelopeType.encryptedVotes ?
            await VotingApi.packageSignedEnvelope({ censusOrigin: processParams.censusOrigin, votes: choices, censusProof, processId, walletOrSigner: wallet, processKeys }) :
            await VotingApi.packageSignedEnvelope({ censusOrigin: processParams.censusOrigin, votes: choices, censusProof, processId, walletOrSigner: wallet })

            console.log('attempting to submit for the account: ' + account.privateKey)

        await VotingApi.submitEnvelope(envelope, wallet, gwPool)

        // wait a bit
        await new Promise(resolve => setTimeout(resolve, 11000))

        const nullifier = VotingApi.getSignedVoteNullifier(wallet.address, processId)
        const envelopeStatus = await VotingApi.getEnvelopeStatus(processId, nullifier, gwPool)
        const stopOnError = false
        console.log(envelopeStatus)
       // if (stopOnError) assert(registered)
    }, { concurrency: 100 })

    console.log()
}

async function checkVoteResults(processId, processMetadata, gwPool) {
    assert.strictEqual(typeof processId, "string")

        console.log("Waiting a bit for the votes to be received", processId)
        const nextBlock = 2 + await VotingApi.getBlockHeight(gwPool)
        await VochainWaiter.waitUntil(nextBlock, gwPool, { verbose: true })

        console.log("Fetching the number of votes for", processId)
        const envelopeHeight = await VotingApi.getEnvelopeHeight(processId, gwPool)
       // assert.strictEqual(envelopeHeight, config.privKeys.length)

        const processState = await VotingApi.getProcessState(processId, gwPool)

        console.log("Waiting for the process to end", processId)
        await VochainWaiter.waitUntil(processState.endBlock, gwPool, { verbose: true })

    console.log("Waiting a bit for the results to be ready", processId)
    await VochainWaiter.wait(2, gwPool, { verbose: true })

    console.log("Fetching the vote results for", processId)
    const rawResults = await VotingApi.getResults(processId, gwPool)
    const totalVotes = await VotingApi.getEnvelopeHeight(processId, gwPool)
console.log(rawResults)
console.log(totalVotes)
   // assert.strictEqual(rawResults.results.length, 1)
    //assert(rawResults.results[0])


    //assert.strictEqual(totalVotes, config.privKeys.length)
}


async function runDispute(relationshipAddress) {
    /* Setup */

    //set accounts
    const provider = new ethers.providers.JsonRpcProvider()
    const employerSigner = provider.getSigner(5)
    console.log('Employer address: ' + employerSigner.getAddress())
    const workerSigner = provider.getSigner(6)
    console.log('Worker address: ' + workerSigner.getAddress())
    const entityWallet = new ethers.Wallet("0x6370fd033278c143179d81c5526140625662b8daa446c22ee2d73db3707e620c", provider)
    console.log("Entity ID", entityWallet.address)

    //create dispute
    const disputeInterface = require('../artifacts/contracts/dispute/Dispute.sol/Dispute.json')

    const disputeAbi = disputeInterface.abi
    const disputeBytecode = disputeInterface.bytecode
    const contractFactory = new ethers.ContractFactory(abi, bytecode, signer)

    const ipfsComplaintHash = 'Jd87KSDF'
    const otherIpfsComplaintHash = 'yO9e8hK3'
    const disputeContract = await contractFactory.deploy(relationshipAddress, ipfsComplaintHash, otherIpfsComplaintHash);
    const contractAddress = disputeContract.address

    console.log('Dispute contract deployed at address: ' + contractAddress)

    //gather N arbitrators
    


    //setup vocdoni
    const gwPool = await connectGateways()

    /* Setup Vocdoni */
    await ensureEntityMetadata(entityWallet, gwPool)
    console.log('ensureEntityMetadata() completed..')


      // Create a new voting process
      const result = await launchNewVote(entityWallet, gwPool)
      console.log('Result:')
      console.log(result)
      processId = result.processId
      processParams = result.processParams
      processMetadata = result.processMetadata
      //assert(processId)
      //assert(processParams)
      //assert(processMetadata)
      //writeFileSync(config.processInfoFilePath, JSON.stringify({ processId, processMetadata }, null, 2))

      await waitUntilPresent(processId, gwPool)

      console.log("- Entity Addr", processParams.entityAddress)
      console.log("- Process ID", processId)
      console.log("- Process start block", processParams.startBlock)
      console.log("- Process end block", processParams.startBlock + processParams.blockCount)
      console.log("- Process merkle root", processParams.censusRoot)
      console.log("- Process merkle tree", processParams.censusUri)
     // console.log("-", accounts.length, "accounts on the census")

      await waitUntilStarted(processId, processParams.startBlock, gwPool)
  
      const accounts = []//await getAccounts()
      await submitVotes(processId, processParams, processMetadata, [], gwPool)
  
      await checkVoteResults(processId, processMetadata, gwPool)
}


//set relationship address before running
//market created from scripts and relationship created by UI.. then run script
const relationshipAddress = ''
runDispute()