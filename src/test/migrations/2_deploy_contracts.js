
const Migrations = artifacts.require('../../contracts/Migrations.sol')

const UserSummaryFactory = artifacts.require('../../contracts/user/UserSummaryFactory.sol');
const UserSummary = artifacts.require('../../contracts/user/UserSummary.sol');
const UserRegistration = artifacts.require('../../contracts/user/UserRegistration.sol');
const IUserSummary = artifacts.require('../../contracts/user/interface/IUserSummary.sol');

const Market = artifacts.require('../../contracts/market/Market.sol');
const MarketFactory = artifacts.require('../../contracts/market/MarketFactory.sol');

const WorkRelationship = artifacts.require('../../contracts/exchange/WorkRelationship.sol');

const MarketLibrary = artifacts.require('../../contracts/libraries/MarketLib.sol');
const Evaluation = artifacts.require('../../contracts/libraries/Evaluation.sol');
const User = artifacts.require('../../contracts/libraries/User.sol');
const StringUtils = artifacts.require('../../contracts/libraries/StringUtils.sol');

const Dispute = artifacts.require('../../contracts/dispute/Dispute.sol');

const Controllable = artifacts.require('../../contracts/control/Controllable');
const DaiToken = artifacts.require('../../contracts/test/Dai.sol');

module.exports = async function(deployer) {
  const uniqueHash = '#jf84ht'
  await deployer.deploy(StringUtils);
  await deployer.deploy(MarketLibrary);
  await deployer.deploy(Evaluation);

  await deployer.deploy(DaiToken, 5777);

  await deployer.deploy(MarketFactory);
  await deployer.deploy(User);

  await deployer.deploy(WorkRelationship, '0xEb529c2580a84DADC3bb73eecB1ef230fccB242D', 0, "");

  await deployer.link(StringUtils, UserSummary);
  await deployer.link(Evaluation, UserSummary);
  await deployer.link(User, UserSummary);

  await deployer.link(StringUtils, UserSummaryFactory);
  await deployer.deploy(UserSummaryFactory)
  const userSummaryFactory = await UserSummaryFactory.deployed()
  await deployer.link(StringUtils, UserRegistration);
  await deployer.deploy(UserRegistration, userSummaryFactory.address);

  //
  //await deployer.deploy(Dispute);
  await deployer.deploy(Controllable);
};