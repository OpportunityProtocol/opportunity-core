// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IMarketMaker {
    /**
     * @dev To be emitted upon creation of a new market
     */
    event MarketCreated(uint256 indexed marketID, address indexed market, address creator);

    /**
     * @notice Deploys a new market
     * @param _marketName Name of the market to be deployed
     * @param _flatRateRelationshipManager Address of the flat rate relationship manager
     * @param _milestoneRelationshipManager Address of the milestone relationship manager
     * @param _deadlineRelationshipManager Address of the deadline relationship manager
     */
    function createMarket(
        string calldata _marketName,
        address _flatRateRelationshipManager,
        address _milestoneRelationshipManager,
        address _deadlineRelationshipManager) external virtual returns(uint256);
}