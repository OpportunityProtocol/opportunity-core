// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Market.sol";
import "hardhat/console.sol";

contract MarketFactory {
    event MarketCreated(address indexed _market, uint256 indexed index, address owner, 
        string marketName);

    address[] public createdMarkets;
    mapping(uint256 => address) idsToMarkets;

     function createMarket(string memory _marketName) external returns(uint256) {
        Market createdMarket = new Market(_marketName);

        createdMarkets.push(address(createdMarket));
        uint256 marketId = createdMarkets.length - 1;
        idsToMarkets[marketId] = address(createdMarket);

        emit MarketCreated(address(createdMarket), createdMarkets.length, msg.sender, _marketName);
    }
}
