// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/Evaluation.sol";
import "../exchange/WorkRelationship.sol";
import "./libraries/Market.sol";

contract Market is Ownable, Controllable {
event MarketCreated(address indexed marketAddress, string memory owner);
event MarketDestroyed(address indexed marketAddress, string memory owner)
event MarketObservingRelationship(address indexed marketAddress, string indexed memory marketName, address indexed workRelationship);
event MarketUnObservingRelationship(address indexed marketAddress, string indexed memory marketName, address indexed workRelationship);

string private _marketName;
MarketUtil.MarketType _marketType;
uint256 private _averageMarketReputation;
uint256 private _averageMarketWeight;
uint256 private _totalMarketLiquidity;
uint256 private _requiredMarketReputation;

address[] _workRelationships;

modifer onlyDefaultMarkets {

}

modifer onlyCustomMarkets {

}

constructor(string memory marketName, uint256 requiredReputation) {
    _marketName = marketName;
    _requiredReputation = requiredReputation;
    _totalMarketLiquidty = 0;
    emit MarketCreated(address(this), _owner);
}

function addRelationship(address _newRelationship) external {
    require(address != 0);
    _workRelationships.push(_newRelationship);
    emit MarketObservingRelationship(address(this), _marketName, newRelationship)
}

function getWorkRelationships() view external {
    return _workRelationships;
}   

function pauseMarket() external onlyOwner onlyController onlyDefaultMarkets {}

function resumeMarket() external onlyOwner onlyController onlyDefaultMarkets {}

function destroyMarket() internal onlyOwner {
    emit MarketDestroyed(address(this), _owner);
    selfdestruct(); }
}
