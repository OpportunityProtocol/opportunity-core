// We import Chai to use its asserting functions here.
import { expect } from 'chai'
import { ContractReceipt, BigNumber, Event } from 'ethers';
import { ethers } from 'hardhat'
import { UserRegistration } from '../../src/types/UserRegistration'

describe("User Registration", function () {
  // Mocha has four functions that let you hook into the the test runner's
  // lifecyle. These are: `before`, `beforeEach`, `after`, `afterEach`.

  let UserRegistration
  let userRegistrationInstance : UserRegistration
  let user

  // `beforeEach` will run before each test, re-deploying the contract every
  // time. It receives a callback, which can be async.
  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    UserRegistration = await ethers.getContractFactory("UserRegistration");
    [user] = await ethers.getSigners();

    userRegistrationInstance  = await UserRegistration.deploy()
  });

  it("happy path - should register a user and assign a user summary address", async () => {
    const tx = await userRegistrationInstance.connect(user).register()
    const txReceipt : ContractReceipt = await tx.wait()

    const userRegisteredEvent : Event | undefined = txReceipt.events?.find(event => event.event == 'UserRegistered')
    expect(userRegisteredEvent?.args?.[0]).to.equal(user.address)

    const userAssignedTrueIdentificationEvent : Event | undefined = txReceipt.events?.find(event => event.event == 'UserAssignedTrueIdentification')
    expect(userAssignedTrueIdentificationEvent?.args?.[0]).to.equal(user.address)

    const userSummaryCreated : Event | undefined = txReceipt.events?.find(event => event.event == 'UserSummaryCreated')
    const summaries = await userRegistrationInstance.functions.userSummaries(0)
    const universalAddressesToUserSummaryAddresses = await userRegistrationInstance.functions.universalToUserSummary(user.address);
    
    expect(summaries[0]).to.equal(universalAddressesToUserSummaryAddresses[0])
    expect(userSummaryCreated?.args?.[0]).to.equal(summaries[0])
    expect(userSummaryCreated?.args?.[1]).to.equal(BigNumber.from('1'))
    expect(userSummaryCreated?.args?.[2]).to.equal(user.address)
  })

  it('sad path - should revert if an address is already registered', async () => {
    const txOne = await userRegistrationInstance.connect(user).register()
    expect(userRegistrationInstance.connect(user).register()).to.be.revertedWith("A user has already been registered with this address.");
  })

});