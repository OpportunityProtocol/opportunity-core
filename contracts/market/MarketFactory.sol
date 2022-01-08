// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./Market.sol";
import "../libraries/MarketLib.sol";
import "hardhat/console.sol";

/**
 * MarketFactory
 * Creates markets
 */
contract MarketFactory {
    event MarketCreated(address indexed _market, uint256 indexed index, address owner, 
        string marketName);
    event MarketDestroyed(address indexed _marketAddress);

    address[] public _createdMarkets;
    mapping(uint256 => address) idsToMarkets;

    /**
     * Creates a Market contract based on the market name and type.  The market contract will generate and assign
     * a unique id to the market.
     * @param _marketName The name of the market
     * @param _marketType The type of the market
     */
     function createMarket(string memory _marketName, MarketLib.MarketType _marketType) external returns(uint256) {
        Market createdMarket = new Market(_marketName, _marketType);

        console.log('Market created at address: ', address(createdMarket));
        _createdMarkets.push(address(createdMarket));
        uint256 marketId = _createdMarkets.length - 1;
        idsToMarkets[marketId] = address(createdMarket);

        emit MarketCreated(address(createdMarket), _createdMarkets.length, msg.sender, _marketName);
    }

    /**
     * Returns the number of markets created.
     * @return The number of markets created
     */
     function getNumMarkets() public view returns (uint256) {
         return _createdMarkets.length;
     }

    /**
     * Returns the number of markets created.
     * @return The list of markets created
     */
     function getMarkets() public view returns (address[] memory) {
         return _createdMarkets;
     }
}
