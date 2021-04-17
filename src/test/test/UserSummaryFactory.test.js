
const chai = require('../../scripts/setupChai.js').chai
const expect = require('../../scripts/setupChai.js').expect
const BN = require('bn.js')
//const chaiBN = chai.chaiBN;
var UserSummaryFactory = artifacts.require('UserSummaryFactory');

contract('UserSummaryFactory', async (accounts) => {
    const [deployerAccount] = accounts;

    it('should add user summary contract to private user summaries increasing the array from length 0 to 1', async () => {
        let instance = await UserSummaryFactory.new();

        let userSummaryLength = await instance.getNumUserSummaries();
        expect(userSummaryLength).to.be.bignumber.equal(new BN(0));


        await instance.createUserSummary(0);

        userSummaryLength = await instance.getNumUserSummaries();
        expect(userSummaryLength).to.be.bignumber.equal(new BN(1));
    })
})