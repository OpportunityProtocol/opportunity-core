// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../libraries/RelationshipLibrary.sol";
import "../interface/IMilestoneRelationshipManager.sol";
import "../interface/IEscrow.sol";
import "hardhat/console.sol";

/**
 * @title Contract that handles milestone based relationship management.
 * @author Elijah Hampton
 */
contract MilestoneRelationshipManager is IMilestoneRelationshipManager {
    mapping(uint256 => string) public relationshipIDToMilestones;
    mapping(uint256 => uint256) public relationshipIDToCurrentMilestoneIndex;

    /**
     * @inheritdoc IMilestoneRelationshipManager::initializeContract
     */
    function initializeContract(
        uint256 _relationshipID,
        address _escrow,
        address _valuePtr,
        address _employer,
        string memory _taskMetadataPtr,
        string memory _milestoneMetadataPtr
    ) external override {
        relationshipIDToRelationship[_relationshipID] = RelationshipLibrary
            .Relationship({
                valuePtr: _valuePtr,
                relationshipID: _relationshipID,
                escrow: _escrow,
                marketPtr: msg.sender,
                employer: _employer,
                worker: address(0),
                taskMetadataPtr: _taskMetadataPtr,
                contractStatus: RelationshipLibrary
                    .ContractStatus
                    .AwaitingWorker,
                contractOwnership: RelationshipLibrary
                    .ContractOwnership
                    .Unclaimed,
                wad: 0,
                acceptanceTimestamp: 0
            });

        numRelationships++;
        relationshipIDToMilestones[_relationshipID] = _milestoneMetadataPtr;
        relationshipIDToCurrentMilestoneIndex[_relationshipID] = 0;
    }

    /**
     * @inheritdoc AbstractContractManager::resolve
     */
    function resolve(uint256 _relationshipID) public override {
        RelationshipLibrary.Relationship
            storage relationship = relationshipIDToRelationship[
                _relationshipID
            ];

        require(relationship.employer != address(0));
        require(relationship.worker != address(0));
        require(msg.sender == relationship.employer);
        require(
            relationship.contractStatus ==
                RelationshipLibrary.ContractStatus.AwaitingResolution
        );

        IEscrow(relationship.escrow).releaseFunds(
            _relationshipID,
            (relationship.wad / 4)
        );

        relationship.contractStatus = RelationshipLibrary
            .ContractStatus
            .Resolved;

        emit ContractStatusUpdate();
    }
}
