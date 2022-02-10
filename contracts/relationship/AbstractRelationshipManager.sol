// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../libraries/RelationshipLibrary.sol";
import "../interface/IRelationshipManager.sol";
import "../interface/IEscrow.sol";
import "hardhat/console.sol";


contract AbstractRelationshipManager  {
    uint numRelationships;
    mapping (uint256 => RelationshipLibrary.Relationship) public relationshipsIDToRelationship;

    function resolve(uint256 calldata _relationshipID) external virtual;

    function grantProposalRequest(
        uint256 calldata _relationshipID,
        address calldata _newWorker,
        uint256 calldata _wad,
        string memory _extraData
    ) 
    external 
    virtual
    {
        RelationshipLibrary.Relationship storage relationship = relationshipIDToRelationship[_relationshipID];

        require(msg.sender == relationship.employer);
        require(relationship.worker == address(0));
        require(relationship.contractOwnership == RelationshipLibrary.ContractOwnership.Unclaimed);

        relationship.wad = _wad;
        relationship.worker = _newWorker;
        relationship.acceptanceTimestamp = block.timestamp;

        relationship.contractOwnership = RelationshipLibrary.ContractOwnership.Pending;
        relationship.contractStatus = RelationshipLibrary.ContractStatus.AwaitingWorkerApproval;

        emit ContractStatusUpdated();
        emit ContractOwnershipUpdated();
    }

    function work(uint256 calldata _relationshipID, string memory _extraData)
    external
    virtual
    {
        RelationshipLibrary.Relationship storage relationship = relationshipIDToRelationship[_relationshipID];
        
        require(msg.sender == relationship.worker);
        require(relationship.contractOwnership == RelationshipLibrary.ContractOwnership.Pending);
        require(relationship.contractStatus == RelationshipLibrary.ContractStatus.AwaitingWorkerApproval);

        relationship.escrow.initialize(owner, worker, _extraData, wad);
        relationship.contractOwnership = RelationshipLibrary.ContractOwnership.Claimed;
        relationship.contractStatus = RelationshipLibrary.ContractStatus.AwaitingResolution;
        relationship.acceptanceTimestamp = block.timestamp;

        emit EnteredContract();
        emit ContractStatusUpdated();
        emit ContractOnwershipUpdate();
    }

    function releaseJob(uint256 calldata _relationshipID)
    external
    virtual
    {
        RelationshipLibrary.Relationship storage relationship = relationshipIDToRelationship[_relationshipID];

        require(relationship.contractOwnership == RelationshipLibrary.ContractOwnership.Claimed);

        relationship.worker = address(0);
        relationship.acceptanceTimestamp = 0;
        relationship.wad = 0;
        relationship.contractStatus = ContractStatus.AwaitingWorker;
        relationship.contractOwnership = ContractOwnership.Unclaimed;

        relationship.escrow.surrenderFunds();

        emit ContractStatusUpdated();
        emit ContractOnwershipUpdate();
    }

    function updateTaskMetadataPointer(uint256 calldata _relationshipID, string calldata _newTaskPointerHash)
    external
    virtual
    {
        RelationshipLibrary.Relationship storage relationship = relationshipIDToRelationship[_relationshipID];

        require(msg.sender == relationship.owner);
        require(relationship.contractOwnership == RelationshipLibrary.ContractOwnership.Unclaimed);

        taskMetadataPointer = _newTaskPointerHash;
    }

    function contractStatusNotification(uint256 _data) 
    external 
    virtual
    {
        RelationshipLibrary.Relationship storage relationship = relationshipIDToRelationship[_relationshipID];

        require(msg.sender == address(relationship.escrow));

        if (_data == 0) {
            relationship.contractStatus = RelationshipLibrary.ContractStatus.AwaitingWorker;
        } else if (_data == 1) {
            relationship.contractStatus = RelationshipLibrary.ContractStatus.AwaitingWorkerApproval;
        } else if (_data == 2) {
            relationship.contractStatus = RelationshipLibrary.ContractStatus.AwaitingReview;
        } else if (_data == 3) {
            relationship.contractStatus = RelationshipLibrary.ContractStatus.Approved;
        } else if (_data == 4) {
            relationship.contractStatus = RelationshipLibrary.ContractStatus.PendingDispute;
        } else if (_data == 5) {
            relationship.contractStatus = RelationshipLibrary.ContractStatus.Disputed;
        } else revert InvalidStatus();

        emit ExternalStatusNotification()
    }
    
}