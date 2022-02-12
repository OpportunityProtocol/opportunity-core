// We import Chai to use its asserting functions here.
import { expect } from 'chai'
import { ContractReceipt, BigNumber, Event, Signer } from 'ethers';
import { ethers } from 'hardhat'
import { Market } from '../../src/types/Market'
import { TestDai } from '../../src/types/TestDai'
import { MarketMaker } from '../../src/types/MarketMaker'
import { RelationshipEscrow } from '../../src/types/RelationshipEscrow'
import { SimpleCentralizedArbitrator } from '../../src/types/SimpleCentralizedArbitrator'
import { FlatRateRelationshipManager } from '../../src/types/FlatRateRelationshipManager'
import { MilestoneRelationshipManager } from '../../src/types/MilestoneRelationshipManager'
import { DeadlineRelationshipManager } from '../../src/types/DeadlineRelationshipManager'

describe("Markets", function () {
  // Mocha has four functions that let you hook into the the test runner's
  // lifecyle. These are: `before`, `beforeEach`, `after`, `afterEach`.

  let marketDeployer, employer, worker

  let MarketMaker
  let marketMakerInstance : MarketMaker

  let CentralizedArbitrator
  let centralizedArbitratorInstance: SimpleCentralizedArbitrator

  let FlatRateRelationshipManager
  let MilestoneRelationshipManager
  let DeadlineRelationshipManager

  let flatRateRelationshipManagerInstance : FlatRateRelationshipManager
  let milestoneRelationshipManagerInstance : MilestoneRelationshipManager
  let deadlineRelationshipManagerInstance : DeadlineRelationshipManager

  let RelationshipEscrow
  let relationshipEscrowInstance : RelationshipEscrow

  let TestDai
  let testDaiInstance : TestDai

  const DAI_MAINNET = '0x6b175474e89094c44da98b954eedeac495271d0f'
  const DAI_RINKEBY = '0xc7ad46e0b8a400bb3c915120d284aafba8fc4735'
  const DAI_KOVAN = '0xff795577d9ac8bd7d90ee22b6c1703490b6512fd'

  const FLATE_RATE_CONTRACT_INIT_DATA = { escrow: '0', valuePtr: '0', _taskMetadataPtr: '8dj39Dks8' }
  const MILESTONE_CONTRACT_INIT_DATA = { escrow: '0', valuePtr: '0', taskMetadataPtr: '8js82kd0f', milestoneMetadataPtr: '0dj2mf8gg'}
  const DEADLINE_CONTRACT_INIT_DATA = { escrow: '0', valuePtr: '0', taskMetadataPtr: '8js82kd0f', deadline: new Date().getSeconds()}

  beforeEach(async function () {
    //get appropriate signers
    [marketDeployer, employer, worker ] = await ethers.getSigners();

    //deploy market maker
    MarketMaker = await ethers.getContractFactory("MarketMaker");
    marketMakerInstance  = await MarketMaker.deploy()

    CentralizedArbitrator = await ethers.getContractFactory("SimpleCentralizedArbitrator")
    centralizedArbitratorInstance = await CentralizedArbitrator.deploy()

    RelationshipEscrow = await ethers.getContractFactory("RelationshipEscrow")
    relationshipEscrowInstance = await RelationshipEscrow.deploy(centralizedArbitratorInstance.address)

    TestDai = await ethers.getContractFactory("TestDai")
    testDaiInstance  = await TestDai.deploy(1)

    FLATE_RATE_CONTRACT_INIT_DATA.escrow = relationshipEscrowInstance.address
    FLATE_RATE_CONTRACT_INIT_DATA.valuePtr = testDaiInstance.address

    MILESTONE_CONTRACT_INIT_DATA.escrow = DEADLINE_CONTRACT_INIT_DATA.escrow = FLATE_RATE_CONTRACT_INIT_DATA.escrow
    MILESTONE_CONTRACT_INIT_DATA.valuePtr = DEADLINE_CONTRACT_INIT_DATA.valuePtr = FLATE_RATE_CONTRACT_INIT_DATA.valuePtr

    //deploy relationship managers
    FlatRateRelationshipManager = await ethers.getContractFactory('FlatRateRelationshipManager')
    flatRateRelationshipManagerInstance = await FlatRateRelationshipManager.deploy()

    MilestoneRelationshipManager = await ethers.getContractFactory('MilestoneRelationshipManager')
    milestoneRelationshipManagerInstance = await MilestoneRelationshipManager.deploy()

    DeadlineRelationshipManager = await ethers.getContractFactory('DeadlineRelationshipManager')
    deadlineRelationshipManagerInstance = await DeadlineRelationshipManager.deploy()

    await testDaiInstance.mint(employer.address, 1000)
    await testDaiInstance.mint(worker.address, 1000)

    expect(await testDaiInstance.balanceOf(employer.address)).to.equal(BigNumber.from(1000))
    expect(await testDaiInstance.balanceOf(worker.address)).to.equal(BigNumber.from(1000))
  });

  describe("Market Creation", async () => {
    it("happy path - should deploy a new market and record relationship manager addresses", async () => {
        //create a new market

        const marketDeploymentTx = await marketMakerInstance
        .connect(marketDeployer)
        .createMarket(
            "Test Market One", 
            flatRateRelationshipManagerInstance.address, 
            milestoneRelationshipManagerInstance.address, 
            deadlineRelationshipManagerInstance.address
        )

        const marketDeploymentTxReceipt = await marketDeploymentTx.wait()

        const marketDeploymentTxEvents = marketDeploymentTxReceipt.events?.find(event => event.event == 'MarketCreated')
        const deployedMarketAddress = marketDeploymentTxEvents?.args?.[0]
        const deployedMarketID = marketDeploymentTxEvents?.args?.[1]
        const deployedMarketDeployer = marketDeploymentTxEvents?.args?.[2]
        const deployedMarketName = marketDeploymentTxEvents?.args?.[3]
        const marketsListEntry  = await marketMakerInstance.markets(0)

        expect(deployedMarketID).to.equal(1)
        expect(deployedMarketDeployer).to.equal(marketDeployer.address)
        //expect(deployedMarketName).to.equal('Test Market One')
        expect(marketDeploymentTx).to.emit(marketMakerInstance, 'MarketCreated').withArgs(deployedMarketAddress, deployedMarketID, deployedMarketDeployer, deployedMarketName.hash)
        expect(marketsListEntry).to.equal(deployedMarketAddress)
    })
  
    it("happy path - should create a each type of relationship and represent the correct number of relationships created", async () => {
        const marketDeploymentTx = await marketMakerInstance
        .connect(marketDeployer)
        .createMarket(
            "Test Market One", 
            flatRateRelationshipManagerInstance.address, 
            milestoneRelationshipManagerInstance.address, 
            deadlineRelationshipManagerInstance.address
        )

        const marketDeploymentTxReceipt = await marketDeploymentTx.wait()

        const marketDeploymentTxEvents = marketDeploymentTxReceipt.events?.find(event => event.event == 'MarketCreated')
        const deployedMarketAddress = marketDeploymentTxEvents?.args?.[0]

        const marketInstance = await ethers.getContractAt('Market', deployedMarketAddress)
        
        marketInstance.connect(employer).createFlatRateContract(FLATE_RATE_CONTRACT_INIT_DATA.escrow, FLATE_RATE_CONTRACT_INIT_DATA.valuePtr, FLATE_RATE_CONTRACT_INIT_DATA._taskMetadataPtr)
        marketInstance.connect(employer).createMilestoneContract(MILESTONE_CONTRACT_INIT_DATA.escrow, MILESTONE_CONTRACT_INIT_DATA.valuePtr, MILESTONE_CONTRACT_INIT_DATA.taskMetadataPtr, MILESTONE_CONTRACT_INIT_DATA.milestoneMetadataPtr)
        marketInstance.connect(employer).createDeadlineContract(DEADLINE_CONTRACT_INIT_DATA.escrow, DEADLINE_CONTRACT_INIT_DATA.valuePtr, DEADLINE_CONTRACT_INIT_DATA.taskMetadataPtr, DEADLINE_CONTRACT_INIT_DATA.deadline)
        
        expect(await marketInstance.relationships(0)).to.equal(1)
        expect(await marketInstance.relationships(1)).to.equal(2)
        expect(await marketInstance.relationships(2)).to.equal(3)

    })
  })

  describe("Relationship Functionality", async () => {
    it("happy path - flat rate relationship - employer should create relationship and successfully complete with a worker", async () => {
        const marketDeploymentTx = await marketMakerInstance
        .connect(marketDeployer)
        .createMarket(
            "Test Market One", 
            flatRateRelationshipManagerInstance.address, 
            milestoneRelationshipManagerInstance.address, 
            deadlineRelationshipManagerInstance.address
        )

        const marketDeploymentTxReceipt = await marketDeploymentTx.wait()

        const marketDeploymentTxEvents = marketDeploymentTxReceipt.events?.find(event => event.event == 'MarketCreated')
        const deployedMarketAddress = marketDeploymentTxEvents?.args?.[0]

        const marketInstance  = await ethers.getContractAt('Market', deployedMarketAddress)
        
        await marketInstance.connect(employer).createFlatRateContract(FLATE_RATE_CONTRACT_INIT_DATA.escrow, FLATE_RATE_CONTRACT_INIT_DATA.valuePtr, FLATE_RATE_CONTRACT_INIT_DATA._taskMetadataPtr)

        await flatRateRelationshipManagerInstance.connect(employer).grantProposalRequest(1, worker.address, testDaiInstance.address, 1000, "")
        await testDaiInstance.connect(employer).approve(relationshipEscrowInstance.address, 1000);

        await flatRateRelationshipManagerInstance.connect(worker).work(1, "")

        await flatRateRelationshipManagerInstance.connect(employer).resolve(1)

        expect(await testDaiInstance.balanceOf(employer.address)).to.equal(BigNumber.from(0))
        expect(await testDaiInstance.balanceOf(worker.address)).to.equal(BigNumber.from(2000))
    })
  })
});