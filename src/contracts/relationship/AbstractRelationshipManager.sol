// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../libraries/RelationshipLibrary.sol";
import "../interface/IEscrow.sol";
import "hardhat/console.sol";


abstract contract AbstractRelationshipManager  {
    event EnteredContract();
    event ContractStatusUpdate();
    event ContractOwnershipUpdate();
    event ExternalStatusNotification();

    error InvalidStatus();

    uint numRelationships;
    mapping (uint256 => RelationshipLibrary.Relationship) public  relationshipIDToRelationship;

    function resolve(uint256 _relationshipID) public virtual;

    function getRelationshipData(uint256 _relationshipID) public returns (RelationshipLibrary.Relationship memory) {
        return relationshipIDToRelationship[_relationshipID];
    }

    function grantProposalRequest(
        uint256 _relationshipID,
        address _newWorker,
        address _valuePtr,
        uint256 _wad,
        string memory _extraData
    ) 
    external 
    {
        RelationshipLibrary.Relationship storage relationship =  relationshipIDToRelationship[_relationshipID];

        require(msg.sender == relationship.employer, "Only the employer of this relationship can grant the proposal.");
        require(_newWorker != address(0), "You must grant this proposal to a valid worker.");
        require(relationship.worker == address(0), "This job is already being worked.");
        require(_valuePtr != address(0), "You must enter a valid address for the value pointer.");
        require(_wad != uint256(0), "The payout amount must be greater than 0.");
        require(relationship.contractOwnership == RelationshipLibrary.ContractOwnership.Unclaimed, "This relationship must not already be claimed.");

        relationship.wad = _wad;
        relationship.valuePtr = _valuePtr;
        relationship.worker = _newWorker;
        relationship.acceptanceTimestamp = block.timestamp;

        relationship.contractOwnership = RelationshipLibrary.ContractOwnership.Pending;
        relationship.contractStatus = RelationshipLibrary.ContractStatus.AwaitingWorkerApproval;

        emit ContractStatusUpdate();
        emit ContractOwnershipUpdate();
    }

    function work(uint256 _relationshipID, string memory _extraData)
    external
    {
        RelationshipLibrary.Relationship storage relationship =  relationshipIDToRelationship[_relationshipID];
        
        require(msg.sender == relationship.worker);
        require(relationship.contractOwnership == RelationshipLibrary.ContractOwnership.Pending);
        require(relationship.contractStatus == RelationshipLibrary.ContractStatus.AwaitingWorkerApproval);

        IEscrow(relationship.escrow).initialize(_relationshipID, _extraData);
        relationship.contractOwnership = RelationshipLibrary.ContractOwnership.Claimed;
        relationship.contractStatus = RelationshipLibrary.ContractStatus.AwaitingResolution;
        relationship.acceptanceTimestamp = block.timestamp;

        emit EnteredContract();
        emit ContractStatusUpdate();
        emit ContractOwnershipUpdate();
    }

    function releaseJob(uint256 _relationshipID)
    external
    {
        RelationshipLibrary.Relationship storage relationship =  relationshipIDToRelationship[_relationshipID];

        require(relationship.contractOwnership == RelationshipLibrary.ContractOwnership.Claimed);

        relationship.worker = address(0);
        relationship.acceptanceTimestamp = 0;
        relationship.wad = 0;
        relationship.contractStatus = RelationshipLibrary.ContractStatus.AwaitingWorker;
        relationship.contractOwnership = RelationshipLibrary.ContractOwnership.Unclaimed;

        IEscrow(relationship.escrow).surrenderFunds(_relationshipID);

        emit ContractStatusUpdate();
        emit ContractOwnershipUpdate();
    }

    function updateTaskMetadataPointer(uint256 _relationshipID, string calldata _newTaskPointerHash)
    external
    {
        RelationshipLibrary.Relationship storage relationship =  relationshipIDToRelationship[_relationshipID];

        require(msg.sender == relationship.employer);
        require(relationship.contractOwnership == RelationshipLibrary.ContractOwnership.Unclaimed);

        relationship.taskMetadataPtr = _newTaskPointerHash;
    }

    function contractStatusNotification(uint256 _relationshipID, RelationshipLibrary.ContractStatus _status) 
    external 
    {
        RelationshipLibrary.Relationship storage relationship =  relationshipIDToRelationship[_relationshipID];

        require(msg.sender == address(relationship.escrow));

        relationship.contractStatus = _status;

        emit ExternalStatusNotification();
    }
    
}