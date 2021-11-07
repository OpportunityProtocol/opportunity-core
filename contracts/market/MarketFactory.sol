// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./Market.sol";
import "../libraries/MarketLib.sol";

contract MarketFactory {
    event MarketCreated(address indexed _market, uint256 indexed index, address owner, 
        string marketName);
    event MarketDestroyed(address indexed _marketAddress);

    Market[] private _createdMarkets;
    mapping(string => Market) idsToMarkets;

    /**
     * Creates a Market contract based on the market name and type.  The market contract will generate and assign
     * a unique id to the market.
     */
     function createMarket(string memory marketName, MarketLib.MarketType marketType) external {
        Market createdMarket = new Market(marketName, marketType);
        //idsToMarkets[marketId] = marketName;

        _createdMarkets.push(createdMarket);
        emit MarketCreated(address(createdMarket), _createdMarkets.length, msg.sender, marketName);
    }

    /**
     * Destroys a market.
     */
    function destroyMarket(uint32 index) external {
        delete _createdMarkets[index];
        emit MarketDestroyed(address(_createdMarkets[index]));
    }

    /**
     * Returns the number of markets created.
     */
     function getNumMarkets() public view returns (uint256) {
         return _createdMarkets.length;
     }
}