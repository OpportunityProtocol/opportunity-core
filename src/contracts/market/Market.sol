// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../exchange/WorkRelationship.sol";
import "./libraries/Market.sol";

contract Market is Ownable {

string private _marketName;
MarketUtil.MarketType _marketType;
uint256 private _averageMarketReputation;
uint256 private _averageMarketWeight;
uint256 private _totalMarketLiquidity;

address[] _workRelationships;

constructor(string memory marketName) {
    _marketName = marketName
}

function addRelationship(address _newRelationship) external {
    require(address != 0);
    _workRelationships.push(_newRelationship);
}

function updateAverageReputation() private {
    // Cycle through relationships

    // Record user profiles

    // Calculate average reputation
}

function updateAverageMarketWeight() private {
    // Cycle through relationships

    // Record user profiles

    // Calculate average market weight
}

function updateTotalMarketLiquidity() private {
    // Cycle through relationships

    // Record user profiles

    // Calculate average liquidity
}

function destroyMarket() internal onlyOwner {
    selfdestruct()
}
}
