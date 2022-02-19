// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../libraries/RelationshipLibrary.sol";
import "../interface/IEscrow.sol";
import "hardhat/console.sol";

/**
 * @title RelationshipManager Interface
 * @author Elijah Hampton
 */
interface IRelationshipManager {

    /**
     * @notice Initializes the relationship
     * @param _relationshipID The id of the relationship to access
     * @param _escrow Address of the escrow to process relationship funds
     * @param _valuePtr Address of the token used as medium of exchange
     * @param _employer Address of employer (The tx sender)
     * @param _taskMetadataPtr IPFS hash of the relationship metadata
     */
    function initializeContract(
        uint256 _relationshipID,
        uint256 _deadline,
        address _escrow,
        address _valuePtr,
        address _employer,
        uint256 _marketID,
        string calldata _taskMetadataPtr
    ) external;

    /**
     * @notice Initializes the relationship
     * @param _relationshipID The id of the relationship to access
     * @param _escrow Address of the escrow to process relationship funds
     * @param _valuePtr Address of the token used as medium of exchange
     * @param _employer Address of employer (The tx sender)
     * @param _taskMetadataPtr IPFS hash of the relationship metadata
     */
    function initializeContract(
        uint256 _relationshipID,
        uint256 _deadline,
        address _escrow,
        address _valuePtr,
        address _employer,
        uint256 _marketID,
        string calldata _taskMetadataPtr,
        uint256 _numMilestones
    ) external;

    /**
     */
    function grantProposalRequest(
        uint256 _relationshipID,
        address _newWorker,
        address _valuePtr,
        uint256 _wad,
        string memory _extraData
    ) external;

    /**
     * @notice Assigns a worker to the relationship
     * @param _relationshipID The id of the relationship to modify
     * @param _extraData Extra data to be used
     */
    function work(uint256 _relationshipID, string memory _extraData) external;

    /**
     * @notice Unassigns a worker from a relationship and returns funds to employer
     * @param _relationshipID The id of the relationship to modify
     */
    function releaseJob(uint256 _relationshipID) external;

    /**
     * @notice Updates the task metadata IPFS hash
     * @dev This should only be allowed while the contract ownership is in the UNCLAIMED state
     * @param _newTaskPointerHash The new IPFS hash of the metadata
     */
    function updateTaskMetadataPointer(
        uint256 _relationshipID,
        string calldata _newTaskPointerHash
    ) external;

    /**
     * @notice A notification from the relationship escrow to update the relationship status
     * @dev This can be used in the case of the escrow having extra functionality such as dispute interface
     * @param _status The status the relationship should be updated to
     */
    function contractStatusNotification(
        uint256 _relationshipID,
        RelationshipLibrary.ContractStatus _status
    ) external;

    /**
     * @notice Resolves a relationship between employer and worker based on the relationship id
     * @param _relationshipID The id of the relationship to be resolved
     */
    function resolve(uint256 _relationshipID) external;

     /**
     * @notice Returns the data for a relationship
     * @param _relationshipID The id of the relationship to return
     * @return The relationship data
     */
    function getRelationshipData(uint256 _relationshipID) external returns (RelationshipLibrary.Relationship memory);
}
