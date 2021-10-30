let chai = require('chai');
let BN = require('bn.js');

let chaiBN = require('chai-bn')(BN);
let chaiAsPromised = require('chai-as-promised');
chai.use(chaiBN);
chai.use(chaiAsPromised);

exports.chai = chai;
exports.expect = chai.expect;