const UserSummaryFactory = artifacts.require('../../contracts/user/UserSummaryFactory.sol');
const UserSummary = artifacts.require('../../contracts/user/UserSummary.sol');
const UserRegistration = artifacts.require('../../contracts/user/UserRegistration.sol');
const IUserSummary = artifacts.require('../../contracts/user/interface/IUserSummary.sol');

const Market = artifacts.require('../.../contracts/market/Market.sol');
const MarketFactory = artifacts.require('../../contracts/market/MarketFactory.sol');

const MarketLibrary = artifacts.require('../../contracts/libraries/Market.sol');
const Evaluation = artifacts.require('../../contracts/libraries/Evaluation.sol');
const User = artifacts.require('../../contracts/libraries/User.sol');
const StringUtils = artifacts.require('../../contracts/libraries/StringUtils.sol');

const Dispute = artifacts.require('../../contracts/dispute/Dispute.sol');

const Controllable = artifacts.require('../../contracts/control/Controllable');

const TimeLocked = artifacts.require('../../contracts/TimeLocked.sol');

const WorkRelationship = artifacts.require('../../contracts/exchange/WorkRelationship.sol');
const WorkExchange = artifacts.require('../../contracts/exchange/WorkExchange.sol');
const MultiPartyOwneable = artifacts.require('../../contracts/exchange/MultiPartyOwneable.sol');

module.exports = async function(deployer) {
  const uniqueHash = '#jf84ht'
  await deployer.deploy(MarketLibrary);
  await deployer.deploy(Evaluation);
  await deployer.deploy(User);
  await deployer.deploy(StringUtils);

  await deployer.deploy(UserSummaryFactory);
  await deployer.deploy(UserSummary, '#jf84ht');
  await deployer.deploy(UserRegistration);
  await deployer.deploy(IUserSummary);
  //await deployer.deploy(Market, "MarketExample", MarketLibrary.MarketUtil.MarketType.DEFAULT, 0, 0);
  await deployer.deploy(MarketFactory);

  await deployer.deploy(Dispute);
  await deployer.deploy(Controllable);
  await deployer.deploy(TimeLocked);
  await deployer.deploy(WorkRelationship);
  await deployer.deploy(WorkExchange);
  await deployer.deploy(MultiPartyOwneable);
};