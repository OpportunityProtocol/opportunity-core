const { expect } = require("chai");
const { ethers } = require("hardhat");

const DAI_MAINNET_ADDRESS = '0x6b175474e89094c44da98b954eedeac495271d0f'

describe("Dispute contract", function () {
  it("Should setup a new relationship and execute a dispute", async function () {
    const [owner, worker] = await ethers.getSigners();

    const MarketFactory = await ethers.getContractFactory('MarketFactory')
    const marketFactory = await MarketFactory.deploy();

    const Market = await ethers.getContractFactory('Market');
    const dummyMarket = await Market.deploy('Dummy Market', 0);
    await dummyMarket.connect(owner)
    await dummyMarket.createJob(owner, 0, "JD930DMW039", DAI_MAINNET_ADDRESS);

    const WorkRelationship = await ethers.getContractFactory('WorkRelationship')
    const dummyRelationshipAddress = dummyMarket._createdJobs(0).address;
    const dummyRelationship = await WorkRelationship.at(dummyRelationshipAddress)

    //dummyRelationship.assignNewWorker()

    const Greeter = await ethers.getContractFactory("Greeter");
    const greeter = await Greeter.deploy("Hello, world!");
    await greeter.deployed();

    expect(await greeter.greet()).to.equal("Hello, world!");

    const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
});
