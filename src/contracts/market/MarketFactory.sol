// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Market.sol";
import "../libraries/Market.sol";

contract MarketFactory {
    event MarketCreated(Market indexed _market, uint256 indexed index, address _marketAddress);
    Market[] private _createdMarkets;

    constructor() {}

    /**
     * Creates a user summary contract for each user based on their civic ID.
     */
     function createMarket(string memory marketName, MarketUtil.MarketType marketType, uint256 requiredReputation, uint256 requiredIndustryWeight) external {
        Market createdMarket = new Market(marketName, marketType, requiredReputation, requiredIndustryWeight);
        _createdMarkets.push(createdMarket);
        emit MarketCreated(createdMarket, _createdMarkets.length, address(this));
    }

    /**
     *
     */
     function getNumMarkets() public view returns (uint256) {
         return _createdMarkets.length;
     }
}
