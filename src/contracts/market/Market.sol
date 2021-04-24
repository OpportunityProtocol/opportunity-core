// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../libraries/Evaluation.sol";
import "../exchange/WorkRelationship.sol";
import "./libraries/Market.sol";

contract Market is Ownable, Controllable, Pausable {
event MarketCreated(address indexed marketAddress, string memory owner);
event MarketDestroyed(address indexed marketAddress, string memory owner)
event MarketObservingRelationship(address indexed marketAddress, string indexed memory marketName, address indexed workRelationship);
event MarketUnObservingRelationship(address indexed marketAddress, string indexed memory marketName, address indexed workRelationship);
event MarketPaused(address indexed marketAddress);
event MarketResumed(address indexed marketAddress);

string private _marketName;
string private _marketType;
MarketUtil.MarketType _marketType;
uint256 private _requiredMarketReputation;
uint256 private _requiredIndustyWeight;

address[] _workRelationships;

constructor(string memory marketName, uint256 requiredReputation, uint256 requiredIndustryWeight) {
    _marketName = marketName;
    _requiredReputation = requiredReputation;
    _requiredIndustryWeight = requiredIndustryWeight;
    emit MarketCreated(address(this), _owner);
}

function addRelationship(address _newRelationship) external {
    require(address != 0);
    _workRelationships.push(_newRelationship);
    emit MarketObservingRelationship(address(this), _marketName, newRelationship)
}

function pauseMarket() external onlyOwner onlyGlobalController onlyDefaultMarkets onlyNotPausedState {
    setPaused(true);
}

function resumeMarket() external onlyOwner onlyGlobalController onlyDefaultMarkets onlyPausedState {
    setPaused(false);
}

function getContractPausedState() returns(bool) {
    return _isPaused();
}

function destroyMarket() internal onlyOwner {
    emit MarketDestroyed(address(this), _owner);
    selfdestruct(); }
}
