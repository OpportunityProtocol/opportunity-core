const { expect } = require("chai");
const { ethers } = require("hardhat");
const { smock } = require("@defi-wonderland/smock");

describe("Opportunity User Functions", () => {
    let UserRegistrationContract, UserSummaryContract,
    userRegistrationInstance, userSummaryInstance,
    user

    beforeEach(async () => {
        const signers = await ethers.getSigners()
        user = signers[0]
        userTwo = signers[1]

        UserRegistrationContract = await ethers.getContractFactory("UserRegistration")
        UserSummaryContract = await ethers.getContractFactory("UserSummary")
        
        userRegistrationInstance = await UserRegistrationContract.deploy()
    })

    it("should register a user and emit UserRegistered and UserAssignedTrueIdentification events", async () => {
        expect(await userRegistrationInstance.connect(user).register()).to.emit(userRegistrationInstance, "UserRegistered").and.to.emit(userRegistrationInstance, "UserAssignedTrueIdentification")
    })

    it("should revert upon the same address registering again", async () => {
        await userRegistrationInstance.connect(user).register()
        expect(userRegistrationInstance.connect(user).register()).to.be.revertedWith("A user has already been registered with this address.")
    })

    it("should record a users address and user summary address in the userSummaryToAddressMapping", () => {
        //TODO
    })
})