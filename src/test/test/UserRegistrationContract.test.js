
const chai = require('../../scripts/setupChai.js').chai
const expect = require('../../scripts/setupChai.js').expect
const BN = require('bn.js')
//const chaiBN = chai.chaiBN;
var UserRegistration = artifacts.require('UserRegistration');

contract('UserRegistration', (accounts) => {
    const uniqueHash = "jf83hf9f";
    const [universalAddress] = accounts;


    beforeEach(async () => {
        this.userRegistrationInstance = await UserRegistration.new();
    })

    it('should register a new user by providing a unique hash and universal address', () => {
        const instance = this.userRegistrationInstance;
        
        instance.registerNewUser(uniqueHash, universalAddress);

        expect(instance.hasUniversalAddress(uniqueHash, universalAddress)).to.be.true;
        expect(instance.getUniversalAddress(uniqueHash)).to.be.equal(universalAddress);
    })
})