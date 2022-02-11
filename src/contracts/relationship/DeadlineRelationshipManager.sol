// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../libraries/RelationshipLibrary.sol";
import "../interface/IDeadlineRelationshipManager.sol";
import "../interface/IEscrow.sol";
import "hardhat/console.sol";


contract DeadlineRelationshipManager is IDeadlineRelationshipManager {
    mapping(uint256 => uint256) public relationshipIDToDeadline;

    function initializeContract(
        uint256 _relationshipID,
        address _escrow,
        address _valuePtr,
        address _employer,
        string memory _taskMetadataPtr,
        uint256 _deadline
    ) 
    external 
    override
    {
         relationshipIDToRelationship[_relationshipID] = RelationshipLibrary.Relationship({
        valuePtr: _valuePtr,
        relationshipID: _relationshipID,
        escrow: _escrow,
        marketPtr: msg.sender,
        employer: _employer,
        worker: address(0),
        taskMetadataPtr: _taskMetadataPtr,
        contractStatus: RelationshipLibrary.ContractStatus.AwaitingWorker,
        contractOwnership: RelationshipLibrary.ContractOwnership.Unclaimed,
        wad: 0,
        acceptanceTimestamp: 0
        });

        numRelationships++;
        relationshipIDToRelationship[_relationshipID] = relationshipIDToRelationship[_relationshipID];
        relationshipIDToDeadline[_relationshipID] = _deadline;
    }

    function resolve(uint256 _relationshipID)
    public
    override
    {
         RelationshipLibrary.Relationship storage relationship = relationshipIDToRelationship[_relationshipID];

        require(relationship.employer != address(0));
        require(relationship.worker != address(0));
        require(msg.sender == relationship.employer);
        require(relationship.contractStatus == RelationshipLibrary.ContractStatus.AwaitingResolution);

        require(block.timestamp >= relationshipIDToDeadline[_relationshipID]);

        IEscrow(relationship.escrow).releaseFunds(_relationshipID, relationship.wad);

        relationship.contractStatus = RelationshipLibrary.ContractStatus.Resolved;

        emit ContractStatusUpdate();
    }


    
}