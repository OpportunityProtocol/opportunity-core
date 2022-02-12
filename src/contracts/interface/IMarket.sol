// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../libraries/RelationshipLibrary.sol";

/**
 * @title Market interface for Opportunity Markets
 * @author Elijah Hampton
 */
interface IMarket {
    /**
     * @dev To be emitted upon creation of a new relationship
     */
    event RelationshipCreated(
        address indexed owner,
        address indexed relationship,
        address indexed marketAddress
    );

    /**
     * @notice Create a new entry for a flat rate relationship
     * @param _escrow Address of the escrow to process relationship funds
     * @param _valuePtr Address of the token used as medium of exchange
     * @param _taskMetadataPtr IPFS hash of the relationship metadata
     */
    function createFlatRateContract(
        address _escrow,
        address _valuePtr,
        string calldata _taskMetadataPtr
    ) external;

    /**
     * @notice Create a new entry for a flat rate relationship
     * @param _escrow Address of the escrow to process relationship funds
     * @param _valuePtr Address of the token used as medium of exchange
     * @param _taskMetadataPtr IPFS hash of the relationship metadata
     * @param _milestoneMetadataPtr IPFS hash of the relationship milestone metadata
     */
    function createMilestoneContract(
        address _escrow,
        address _valuePtr,
        string calldata _taskMetadataPtr,
        string memory _milestoneMetadataPtr
    ) external;

    /**
     * @notice Create a new entry for a flat rate relationship
     * @param _escrow Address of the escrow to process relationship funds
     * @param _valuePtr Address of the token used as medium of exchange
     * @param _taskMetadataPtr IPFS hash of the relationship metadata
     * @param _deadline Deadline to complete relationship
     */
    function createDeadlineContract(
        address _escrow,
        address _valuePtr,
        string calldata _taskMetadataPtr,
        uint256 _deadline
    ) external;
}
