// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../libraries/RelationshipLibrary.sol";
import "../interface/IFlatRateRelationshipManager.sol";
import "../interface/IEscrow.sol";
import "hardhat/console.sol";


contract FlatRateRelationshipManager is IFlatRateRelationshipManager {
    function initializeContract(
        uint256 _relationshipID,
        address _escrow,
        address _valuePtr,
        address _employer,
        string  memory _taskMetadataPtr
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

        relationship.contractStatus = RelationshipLibrary.ContractStatus.Resolved;

        IEscrow(relationship.escrow).releaseFunds(relationship.wad, _relationshipID);
        emit ContractStatusUpdate();
    } 
}