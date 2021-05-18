// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Market.sol";
import "../libraries/MarketLib.sol";

contract MarketFactory {
    event MarketCreated(Market indexed _market, uint256 indexed index, address _marketAddress);
    event MarketDestroyed(address indexed _marketAddress);
    Market[] private _createdMarkets;

    constructor() {}

    /**
     * Creates a user summary contract for each user based on their civic ID.
     */
     function createMarket(string memory marketName, MarketLib.MarketType marketType) external {
        Market createdMarket = new Market(marketName, marketType);
        _createdMarkets.push(createdMarket);
        emit MarketCreated(createdMarket, _createdMarkets.length, address(this));
    }

    function destroyMarket(address marketAddress) external {
        
    }

    /**
     *
     */
     function getNumMarkets() public view returns (uint256) {
         return _createdMarkets.length;
     }
}
