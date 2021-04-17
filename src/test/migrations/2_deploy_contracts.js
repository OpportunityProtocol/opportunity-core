const Migrations = artifacts.require("../contracts/Migrations.sol");
const UserSummaryFactory = artifacts.require('../../contracts/user/UserSummaryFactory.sol');

module.exports = async function(deployer) {
  deployer.deploy(Migrations);
  await deployer.deploy(UserSummaryFactory);
};