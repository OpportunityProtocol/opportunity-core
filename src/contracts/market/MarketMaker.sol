// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Market.sol";
import "hardhat/console.sol";

contract MarketFactory {
    event MarketCreated(address indexed _market, uint256 indexed index, address owner, 
        string marketName);

    address[] public markets;
    address marketMaker;
    mapping(uint256 => address) idsToMarkets;

    modifier onlyMarketMaker() {
        require(msg.sender == marketMaker);
        _;
    }

    constructor(address _marketMaker) {
        marketMaker = _marketMaker;
    }

     function createMarket(
        string memory _marketName,
        address _flatRateRelationshipManager,
        address _milestoneRelationshipManager,
        address _deadlineRelationshipManager) public onlyMarketMaker returns(uint256) {
        Market market = new Market(
            _marketName,
            _flatRateRelationshipManager,
            _milestoneRelationshipManager,
            _deadlineRelationshipManager);

        markets.push(address(market));
        uint256 marketId = markets.length - 1;
        idsToMarkets[marketId] = address(market);

        emit MarketCreated(address(market), markets.length, msg.sender, _marketName);
    }
}
