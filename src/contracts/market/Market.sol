// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../libraries/Evaluation.sol";
import "../exchange/WorkRelationship.sol";
import "../libraries/Market.sol";
import "../control/Controllable.sol";

contract Market is Ownable, Controllable, Pausable {
event MarketCreated(address indexed marketAddress, address indexed owner, uint256 requiredReputation, uint256 requiredIndustryWeight);
event MarketDestroyed(address indexed marketAddress, address indexed owner);
event MarketObservingRelationship(address indexed marketAddress, string indexed marketName, address indexed workRelationship);
event MarketUnObservingRelationship(address indexed marketAddress, string indexed marketName, address indexed workRelationship);
event MarketPaused(address indexed marketAddress, string indexed marketName);
event MarketResumed(address indexed marketAddress, string indexed marketName);

string private _marketName;
MarketUtil.MarketType private _marketType;
uint256 private _requiredReputation;
uint256 private _requiredIndustryWeight;
MarketUtil.MarketStatus private _marketStatus;

address[] private _workRelationships;

constructor(string memory marketName, MarketUtil.MarketType marketType, uint256 requiredReputation, uint256 requiredIndustryWeight) {
    _marketName = marketName;
    _marketType = marketType;
    _requiredReputation = requiredReputation;
    _requiredIndustryWeight = requiredIndustryWeight;
    emit MarketCreated(address(this), owner(), requiredReputation, requiredIndustryWeight);
}

function addRelationship(address newRelationship) external {
    require(newRelationship != address(0));
    _workRelationships.push(newRelationship);
    emit MarketObservingRelationship(address(this), _marketName, newRelationship);
}

function pauseMarket() external onlyOwner onlyGlobalController(msg.sender) onlyDefaultMarkets(_marketType) onlyNotPausedState(_marketStatus) {
    _pause();
}

function resumeMarket() external onlyOwner onlyGlobalController(msg.sender) onlyDefaultMarkets(_marketType) onlyPausedState(_marketStatus) {
    _unpause();
}

function getMarketState() public returns(bool) {
    return paused();
}

function destroyMarket() internal onlyOwner {
    emit MarketDestroyed(address(this), owner());
    //selfdestruct(); 
    }
}
