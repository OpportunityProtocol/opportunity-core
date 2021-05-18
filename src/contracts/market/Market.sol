// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../libraries/Evaluation.sol";
import "../exchange/WorkRelationship.sol";
import "../libraries/MarketLib.sol";
import "../control/Controllable.sol";

contract Market is Ownable, Controllable, Pausable {
event MarketObservingRelationship(address indexed marketAddress, string indexed marketName, address indexed workRelationship);
event MarketUnObservingRelationship(address indexed marketAddress, string indexed marketName, address indexed workRelationship);
event MarketPaused(address indexed marketAddress, string indexed marketName);
event MarketResumed(address indexed marketAddress, string indexed marketName);

string public _marketName;
MarketLib.MarketType public _marketType;
uint256 public _requiredReputation;
uint256 public _requiredIndustryWeight;
MarketLib.MarketStatus public _marketStatus;

address[] private _workRelationships;

constructor(string memory marketName, MarketLib.MarketType marketType) {
    _marketName = marketName;
    _marketType = marketType;
   // _requiredReputation = requiredReputation;
   // _requiredIndustryWeight = requiredIndustryWeight;
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

function getMarketState() public view returns(bool) { return paused(); }

function getWorkRelationships() external view returns(address[] memory) { return _workRelationships; }

function destroyMarket() internal onlyOwner {
    //selfdestruct(); 
}
}
