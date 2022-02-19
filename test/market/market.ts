// We import Chai to use its asserting functions here.
import { expect } from 'chai'
import { ContractReceipt, BigNumber, Event, Signer } from 'ethers';
import { ethers } from 'hardhat'
import { TestDai } from '../../src/types/TestDai'
import { RelationshipManager } from '../../src/types/RelationshipManager'
import { OpportunityGovernor } from '../../src/types/OpportunityGovernor'
import { RelationshipEscrow } from '../../src/types/RelationshipEscrow'
import { SimpleCentralizedArbitrator } from '../../src/types/SimpleCentralizedArbitrator'
describe("Markets", function () {
  // Mocha has four functions that let you hook into the the test runner's
  // lifecyle. These are: `before`, `beforeEach`, `after`, `afterEach`.

  let marketDeployer, employer, worker

  let OpportunityGovernor
  let opportunityGovernorInstance : OpportunityGovernor

  let RelationshipManager
  let relationshipManagerInstance : RelationshipManager

  let CentralizedArbitrator
  let centralizedArbitratorInstance: SimpleCentralizedArbitrator

  let RelationshipEscrow
  let relationshipEscrowInstance : RelationshipEscrow

  let TestDai
  let testDaiInstance : TestDai

  const DAI_MAINNET = '0x6b175474e89094c44da98b954eedeac495271d0f'
  const DAI_RINKEBY = '0xc7ad46e0b8a400bb3c915120d284aafba8fc4735'
  const DAI_KOVAN = '0xff795577d9ac8bd7d90ee22b6c1703490b6512fd'

  const FLATE_RATE_CONTRACT_INIT_DATA = { escrow: '0', valuePtr: '0', _taskMetadataPtr: '8dj39Dks8' }
  const MILESTONE_CONTRACT_INIT_DATA = { escrow: '0', valuePtr: '0', taskMetadataPtr: '8js82kd0f', numMilstones: 5}

  beforeEach(async function () {
    //get appropriate signers
    [marketDeployer, employer, worker ] = await ethers.getSigners();

    //deploy governor
    OpportunityGovernor = await ethers.getContractFactory('OpportunityGovernor')
    opportunityGovernorInstance = await OpportunityGovernor.deploy()

    RelationshipManager = await ethers.getContractFactory('RelationshipManager')
    relationshipManagerInstance = await RelationshipManager.deploy()

    CentralizedArbitrator = await ethers.getContractFactory("SimpleCentralizedArbitrator")
    centralizedArbitratorInstance = await CentralizedArbitrator.deploy()

    RelationshipEscrow = await ethers.getContractFactory("RelationshipEscrow")
    relationshipEscrowInstance = await RelationshipEscrow.deploy(centralizedArbitratorInstance.address)

    TestDai = await ethers.getContractFactory("TestDai")
    testDaiInstance  = await TestDai.deploy(1)

    FLATE_RATE_CONTRACT_INIT_DATA.escrow = relationshipEscrowInstance.address
    FLATE_RATE_CONTRACT_INIT_DATA.valuePtr = testDaiInstance.address

    MILESTONE_CONTRACT_INIT_DATA.escrow = FLATE_RATE_CONTRACT_INIT_DATA.escrow
    MILESTONE_CONTRACT_INIT_DATA.valuePtr = FLATE_RATE_CONTRACT_INIT_DATA.valuePtr

    //deploy relationship managers
    RelationshipManager = await ethers.getContractFactory('RelationshipManager')
    relationshipManagerInstance = await RelationshipManager.deploy()

    await testDaiInstance.mint(employer.address, 1000)
    await testDaiInstance.mint(worker.address, 1000)

    expect(await testDaiInstance.balanceOf(employer.address)).to.equal(BigNumber.from(1000))
    expect(await testDaiInstance.balanceOf(worker.address)).to.equal(BigNumber.from(1000))
  });

  describe("Market Creation", async () => {
    it("happy path - should deploy a new market and record relationship manager addresses", async () => {
        //create a new market

        const marketDeploymentTx = await opportunityGovernorInstance
        .connect(marketDeployer)
        .createMarket(
            "Test Market One", 
            relationshipManagerInstance.address,
            testDaiInstance.address
        )

        const marketDeploymentTxReceipt = await marketDeploymentTx.wait()

        const marketDeploymentTxEvents = marketDeploymentTxReceipt.events?.find(event => event.event == 'MarketCreated')
        const deployedMarketID = marketDeploymentTxEvents?.args?.[0]
        const deployedMarketDeployer = marketDeploymentTxEvents?.args?.[1]
        const deployedMarketName = marketDeploymentTxEvents?.args?.[2]
        const marketsListEntry  = await opportunityGovernorInstance.markets(0)

        expect(deployedMarketID).to.equal(1)
        expect(deployedMarketDeployer).to.equal(marketDeployer.address)
        //expect(deployedMarketName).to.equal('Test Market One')
        expect(marketDeploymentTx).to.emit(opportunityGovernorInstance, 'MarketCreated').withArgs(deployedMarketID, deployedMarketDeployer, deployedMarketName.hash)
        expect(marketsListEntry[0]).to.equal('Test Market One')
    })
  })

  describe("Relationship Functionality", async () => {
    it("happy path - flat rate relationship - employer should create relationship and successfully complete with a worker", async () => {
      console.log(relationshipManagerInstance.address) 
      const marketDeploymentTx = await opportunityGovernorInstance
        .connect(marketDeployer)
        .createMarket(
          "Test Market One", 
          relationshipManagerInstance.address,
          testDaiInstance.address
        )

        const marketDeploymentTxReceipt = await marketDeploymentTx.wait()
        const marketDeploymentTxEvents = marketDeploymentTxReceipt.events?.find(event => event.event == 'MarketCreated')
        const deployedMarketAddress = marketDeploymentTxEvents?.args?.[0]

        await opportunityGovernorInstance
        .connect(employer)
        .createFlatRateRelationship(
          BigNumber.from(1), 
          relationshipEscrowInstance.address, 
          FLATE_RATE_CONTRACT_INIT_DATA._taskMetadataPtr, 
          BigNumber.from(0)
        )

        await relationshipManagerInstance.connect(employer).grantProposalRequest(1, worker.address, testDaiInstance.address, 1000, "")
        
        await testDaiInstance.connect(employer).approve(relationshipEscrowInstance.address, 1000);

        await relationshipManagerInstance.connect(worker).work(1, "")

        await relationshipManagerInstance.connect(employer).resolve(1)

        expect(await testDaiInstance.balanceOf(employer.address)).to.equal(BigNumber.from(0))
        expect(await testDaiInstance.balanceOf(worker.address)).to.equal(BigNumber.from(2000))
    })
  })
});