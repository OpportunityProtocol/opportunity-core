// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "hardhat/console.sol";
import "./libraries/RelationshipLibrary.sol";
import "./interface/IRelationshipManager.sol";

contract OpportunityGovernor {
    /**
     * @dev To be emitted upon deploying a market
     */
    event MarketCreated(
        uint256 indexed index,
        address indexed creator,
        string indexed marketName
    );

    RelationshipLibrary.Market[] public markets;
    mapping(uint256 => RelationshipLibrary.Market) public marketIDToMarket;

    /**
     */
    function createMarket(
        string memory _marketName,
        address _relationshipManager,
        address _valuePtr
    ) public returns (uint256) {
        uint256 marketId = markets.length - 1;

        marketIDToMarket[marketId] = RelationshipLibrary.Market({
            marketName: _marketName,
            marketID: marketId,
            relationshipManager: _relationshipManager,
            relationships: new uint256[](0),
            valuePtr: _valuePtr
        });

        markets.push(marketIDToMarket[marketId]);

            emit MarketCreated(
            markets.length,
            msg.sender,
            _marketName
        );
        

        return markets.length;
    }

    /**
     * @param _marketID The id of the market to create the relationship
     * @param _escrow The address of the escrow for this relationship
     * @param _taskMetadataPtr The hash on IPFS for the relationship metadata
     * @param _deadline The deadline for the worker to complete the relationship
     */
    function createFlatRateRelationship(
        uint256 _marketID, 
        address _escrow, 
        string calldata _taskMetadataPtr, 
        uint256 _deadline
    ) external {
        RelationshipLibrary.Market storage market = marketIDToMarket[_marketID];
        uint256 relationshipID = market.relationships.length + 1;

        IRelationshipManager(market.relationshipManager).initializeContract(
            relationshipID,
            _deadline,
            _escrow,
            market.valuePtr,
            msg.sender,
            _marketID,
            _taskMetadataPtr
        );


        market.relationships.push(relationshipID);
    }

    /**
     * @param _marketID The id of the market to create the relationship
     * @param _escrow The address of the escrow for this relationship
     * @param _taskMetadataPtr The hash on IPFS for the relationship metadata
     * @param _deadline The deadline for the worker to complete the relationship
     * @param _numMilestones The number of milestones in this relationship
     */
    function createMilestoneRelationship(
        uint256 _marketID, 
        address _escrow, 
        string calldata _taskMetadataPtr, 
        uint256 _deadline, 
        uint256 _numMilestones
    ) external {
        RelationshipLibrary.Market storage market = marketIDToMarket[_marketID];
        uint256 relationshipID = market.relationships.length + 1;

        IRelationshipManager(market.relationshipManager).initializeContract(
            relationshipID,
            _deadline,
            _escrow,
            market.valuePtr,
            msg.sender,
            _marketID,
            _taskMetadataPtr,
            _numMilestones
        );

        market.relationships.push(relationshipID);
    }

    function submitReview(uint256 _marketID, uint _relationshipID) external {
        
    }
}
