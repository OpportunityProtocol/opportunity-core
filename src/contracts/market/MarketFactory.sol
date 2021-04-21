// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Market.sol";

contract MarketFactory {
    event MarketCreated(Market indexed _market, uint256 indexed index, address _marketAddress);
    Market[] private _createdMarkets;

    constructor() {}

    /**
     * Creates a user summary contract for each user based on their civic ID.
     */
     function createMarket(string memory marketName) external returns(address) {
        Market createdMarket = new Market(marketName);
        emit MarketCreated(createdMarket, index, address(this));
        _createdMarkets.push(createdMarket);

        address marketAddress = createdMarket.getContractAddress();
        return marketAddress;
    }

    /**
     *
     */
     function getNumMarkets() public view returns (uint256) {
         return _createdMarkets.length;
     }
}
