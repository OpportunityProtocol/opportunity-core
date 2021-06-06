// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./Market.sol";
import "../libraries/MarketLib.sol";

contract MarketFactory {
    event MarketCreated(Market indexed _market, uint256 indexed index, address owner, string marketName, MarketLib.MarketType marketType);
    event MarketDestroyed(address indexed _marketAddress);
    Market[] private _createdMarkets;


    /**
     * Creates a user summary contract for each user based on their civic ID.
     */
     function createMarket(string memory marketName, MarketLib.MarketType marketType) external {
        Market createdMarket = new Market(marketName, marketType);
        _createdMarkets.push(createdMarket);
        emit MarketCreated(createdMarket, _createdMarkets.length, msg.sender, marketName, marketType);
    }

    function destroyMarket(uint32 index) external {
        delete _createdMarkets[index];
    }

    /**
     *
     */
     function getNumMarkets() public view returns (uint256) {
         return _createdMarkets.length;
     }
}
