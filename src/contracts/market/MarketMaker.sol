// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interface/IMarketMaker.sol";
import "./Market.sol";
import "hardhat/console.sol";

contract MarketMaker is IMarketMaker {
    /**
     * @dev To be emitted upon deploying a market
     */
    event MarketCreated(
        address indexed _market,
        uint256 index,
        address indexed owner,
        string indexed marketName
    );

    address[] public markets;
    mapping(uint256 => address) idsToMarkets;

    /**
     * @inheritdoc IMarketMaker
     */
    function createMarket(
        string memory _marketName,
        address _flatRateRelationshipManager,
        address _milestoneRelationshipManager,
        address _deadlineRelationshipManager
    ) public override returns (uint256) {
        Market market = new Market(
            _marketName,
            _flatRateRelationshipManager,
            _milestoneRelationshipManager,
            _deadlineRelationshipManager
        );

        markets.push(address(market));
        uint256 marketId = markets.length - 1;
        idsToMarkets[marketId] = address(market);

        emit MarketCreated(
            address(market),
            markets.length,
            msg.sender,
            _marketName
        );
    }
}
