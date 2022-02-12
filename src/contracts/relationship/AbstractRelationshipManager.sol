// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../libraries/RelationshipLibrary.sol";
import "../interface/IEscrow.sol";
import "hardhat/console.sol";

/**
 * @title Abstract relationship manager template.
 * @author Elijah Hampton
 */
abstract contract AbstractRelationshipManager {
    /**
     * @dev To be emitted upon employer and worker entering contract.
     */
    event EnteredContract();

    /**
     * @dev To be emitted upon relationship status update
     */
    event ContractStatusUpdate();

    /**
     * @dev To be emitted upon relationship ownership update
     */
    event ContractOwnershipUpdate();

    /**
     * @dev To be emitted upon external state update from escrow
     */
    event ExternalStatusNotification();

    error InvalidStatus();

    uint256 numRelationships;
    mapping(uint256 => RelationshipLibrary.Relationship)
        public relationshipIDToRelationship;

    /**
     * @notice Resolves a relationship between employer and worker based on the relationship id
     * @param _relationshipID The id of the relationship to be resolved
     */
    function resolve(uint256 _relationshipID) public virtual;

    /**
     * @notice Returns the data for a relationship
     * @param _relationshipID The id of the relationship to return
     * @return The relationship data
     */
    function getRelationshipData(uint256 _relationshipID)
        public
        returns (RelationshipLibrary.Relationship memory)
    {
        return relationshipIDToRelationship[_relationshipID];
    }

    function grantProposalRequest(
        uint256 _relationshipID,
        address _newWorker,
        address _valuePtr,
        uint256 _wad,
        string memory _extraData
    ) external {
        RelationshipLibrary.Relationship
            storage relationship = relationshipIDToRelationship[
                _relationshipID
            ];

        require(
            msg.sender == relationship.employer,
            "Only the employer of this relationship can grant the proposal."
        );
        require(
            _newWorker != address(0),
            "You must grant this proposal to a valid worker."
        );
        require(
            relationship.worker == address(0),
            "This job is already being worked."
        );
        require(
            _valuePtr != address(0),
            "You must enter a valid address for the value pointer."
        );
        require(
            _wad != uint256(0),
            "The payout amount must be greater than 0."
        );
        require(
            relationship.contractOwnership ==
                RelationshipLibrary.ContractOwnership.Unclaimed,
            "This relationship must not already be claimed."
        );

        relationship.wad = _wad;
        relationship.valuePtr = _valuePtr;
        relationship.worker = _newWorker;
        relationship.acceptanceTimestamp = block.timestamp;

        relationship.contractOwnership = RelationshipLibrary
            .ContractOwnership
            .Pending;
        relationship.contractStatus = RelationshipLibrary
            .ContractStatus
            .AwaitingWorkerApproval;

        emit ContractStatusUpdate();
        emit ContractOwnershipUpdate();
    }

    /**
     * @notice Assigns a worker to the relationship
     * @param _relationshipID The id of the relationship to modify
     * @param _extraData Extra data to be used
     */
    function work(uint256 _relationshipID, string memory _extraData) external {
        RelationshipLibrary.Relationship
            storage relationship = relationshipIDToRelationship[
                _relationshipID
            ];

        require(msg.sender == relationship.worker);
        require(
            relationship.contractOwnership ==
                RelationshipLibrary.ContractOwnership.Pending
        );
        require(
            relationship.contractStatus ==
                RelationshipLibrary.ContractStatus.AwaitingWorkerApproval
        );

        IEscrow(relationship.escrow).initialize(_relationshipID, _extraData);
        relationship.contractOwnership = RelationshipLibrary
            .ContractOwnership
            .Claimed;
        relationship.contractStatus = RelationshipLibrary
            .ContractStatus
            .AwaitingResolution;
        relationship.acceptanceTimestamp = block.timestamp;

        emit EnteredContract();
        emit ContractStatusUpdate();
        emit ContractOwnershipUpdate();
    }

    /**
     * @notice Unassigns a worker from a relationship and returns funds to employer
     * @param _relationshipID The id of the relationship to modify
     */
    function releaseJob(uint256 _relationshipID) external {
        RelationshipLibrary.Relationship
            storage relationship = relationshipIDToRelationship[
                _relationshipID
            ];

        require(
            relationship.contractOwnership ==
                RelationshipLibrary.ContractOwnership.Claimed
        );

        relationship.worker = address(0);
        relationship.acceptanceTimestamp = 0;
        relationship.wad = 0;
        relationship.contractStatus = RelationshipLibrary
            .ContractStatus
            .AwaitingWorker;
        relationship.contractOwnership = RelationshipLibrary
            .ContractOwnership
            .Unclaimed;

        IEscrow(relationship.escrow).surrenderFunds(_relationshipID);

        emit ContractStatusUpdate();
        emit ContractOwnershipUpdate();
    }

    /**
     * @notice Updates the task metadata IPFS hash
     * @dev This should only be allowed while the contract ownership is in the UNCLAIMED state
     * @param _newTaskPointerHash The new IPFS hash of the metadata
     */
    function updateTaskMetadataPointer(
        uint256 _relationshipID,
        string calldata _newTaskPointerHash
    ) external {
        RelationshipLibrary.Relationship
            storage relationship = relationshipIDToRelationship[
                _relationshipID
            ];

        require(msg.sender == relationship.employer);
        require(
            relationship.contractOwnership ==
                RelationshipLibrary.ContractOwnership.Unclaimed
        );

        relationship.taskMetadataPtr = _newTaskPointerHash;
    }

    /**
     * @notice A notification from the relationship escrow to update the relationship status
     * @dev This can be used in the case of the escrow having extra functionality such as dispute interface
     * @param _status The status the relationship should be updated to
     */
    function contractStatusNotification(
        uint256 _relationshipID,
        RelationshipLibrary.ContractStatus _status
    ) external {
        RelationshipLibrary.Relationship
            storage relationship = relationshipIDToRelationship[
                _relationshipID
            ];

        require(msg.sender == address(relationship.escrow));

        relationship.contractStatus = _status;

        emit ExternalStatusNotification();
    }
}
