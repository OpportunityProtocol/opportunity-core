// We import Chai to use its asserting functions here.
import { expect } from 'chai'
import { ContractReceipt, BigNumber, Event, Signer } from 'ethers';
import {ethers} from 'hardhat'
import { TestDai } from '../../src/types/TestDai'
import { SimpleCentralizedArbitrator } from '../../src/types/SimpleCentralizedArbitrator'

import { task } from 'hardhat/config';
import { LensHub__factory } from '../../src/lens-protocol/typechain-types';
import { CreateProfileDataStruct } from '../../src/lens-protocol/typechain-types/LensHub';
import { waitForTx, initEnv, getAddrs, ZERO_ADDRESS } from '../../src/lens-protocol/tasks/helpers/utils';

describe("Markets", function () {
  let marketDeployer, employer, worker, governance, treasury

  let GigEarth
  let gigEarthInstance

  let CentralizedArbitrator
  let centralizedArbitratorInstance: SimpleCentralizedArbitrator

  let TestDai
  let testDaiInstance : TestDai

  const FLATE_RATE_CONTRACT_INIT_DATA = { escrow: '0', valuePtr: '0', _taskMetadataPtr: '8dj39Dks8' }
  const MILESTONE_CONTRACT_INIT_DATA = { escrow: '0', valuePtr: '0', taskMetadataPtr: '8js82kd0f', numMilstones: 5}

  const LENS_HUB_ADDRESS = "0x038B86d9d8FAFdd0a02ebd1A476432877b0107C8"

  beforeEach(async function () {
    //get appropriate signers
    [marketDeployer, employer, worker, governance, treasury] = await ethers.getSigners();

    // Deploy smart contracts
    CentralizedArbitrator = await ethers.getContractFactory("SimpleCentralizedArbitrator")
    centralizedArbitratorInstance = await CentralizedArbitrator.deploy()

    TestDai = await ethers.getContractFactory("TestDai")
    testDaiInstance  = await TestDai.deploy(1)

    //deploy governor
    GigEarth = await ethers.getContractFactory('')
    gigEarthInstance = await GigEarth.deploy(governance, treasury, centralizedArbitratorInstance.address, LENS_HUB_ADDRESS)

    //set gig earth reference and follow modules
    gigEarthInstance.setLensFollowModule()
    gigEarthInstance.setLensContentReferenceModule()

    // Set default values for contracts to deploy
    FLATE_RATE_CONTRACT_INIT_DATA.escrow = '0'
    FLATE_RATE_CONTRACT_INIT_DATA.valuePtr = testDaiInstance.address

    MILESTONE_CONTRACT_INIT_DATA.escrow = FLATE_RATE_CONTRACT_INIT_DATA.escrow
    MILESTONE_CONTRACT_INIT_DATA.valuePtr = FLATE_RATE_CONTRACT_INIT_DATA.valuePtr

    // mint test dai to employer and worker
    await testDaiInstance.mint(employer.address, 1000)
    await testDaiInstance.mint(worker.address, 1000)

    expect(await testDaiInstance.balanceOf(employer.address)).to.equal(BigNumber.from(1000))
    expect(await testDaiInstance.balanceOf(worker.address)).to.equal(BigNumber.from(1000))
  });

  describe("Market Creation", async () => {
    it("happy path - should deploy a new market and record relationship manager addresses", async () => {
        //create a new market
        const marketDeploymentTx = await gigEarthInstance
        .connect(marketDeployer)
        .createMarket(
            "Test Market One", 
            testDaiInstance.address
        )

        const marketDeploymentTxReceipt = await marketDeploymentTx.wait()

        const marketDeploymentTxEvents = marketDeploymentTxReceipt.events?.find(event => event.event == 'MarketCreated')
        const deployedMarketID = marketDeploymentTxEvents?.args?.[0]
        const deployedMarketDeployer = marketDeploymentTxEvents?.args?.[1]
        const deployedMarketName = marketDeploymentTxEvents?.args?.[2]
        const marketsListEntry  = await gigEarthInstance.markets(0)

        expect(deployedMarketID).to.equal(1)
        expect(deployedMarketDeployer).to.equal(marketDeployer.address)
        //expect(deployedMarketName).to.equal('Test Market One')
        expect(marketDeploymentTx).to.emit(gigEarthInstance, 'MarketCreated').withArgs(deployedMarketID, deployedMarketDeployer, deployedMarketName.hash)
        expect(marketsListEntry[0]).to.equal('Test Market One')
    })
  })

  describe("Relationship Functionality", async () => {
    it("happy path - flat rate relationship - employer should create relationship and successfully complete with a worker", async () => {
      const marketDeploymentTx = await gigEarthInstance
        .connect(marketDeployer)
        .createMarket(
          "Test Market One", 
          testDaiInstance.address
        )

        const marketDeploymentTxReceipt = await marketDeploymentTx.wait()
        const marketDeploymentTxEvents = marketDeploymentTxReceipt.events?.find(event => event.event == 'MarketCreated')
        const deployedMarketAddress = marketDeploymentTxEvents?.args?.[0]

        await gigEarthInstance
        .connect(employer)
        .createFlatRateRelationship(
          BigNumber.from(1), 
          FLATE_RATE_CONTRACT_INIT_DATA._taskMetadataPtr, 
          BigNumber.from(0)
        )

        await gigEarthInstance.connect(employer).grantProposalRequest(1, worker.address, testDaiInstance.address, 1000, "")
        
        await testDaiInstance.connect(employer).approve(gigEarthInstance.address, 1000);

        await gigEarthInstance.connect(worker).work(1, "")

        await gigEarthInstance.connect(employer).resolve(1)

        expect(await testDaiInstance.balanceOf(employer.address)).to.equal(BigNumber.from(0))
        expect(await testDaiInstance.balanceOf(worker.address)).to.equal(BigNumber.from(2000))
    })
  })
});