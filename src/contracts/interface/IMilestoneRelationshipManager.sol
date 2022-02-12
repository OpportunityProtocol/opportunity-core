// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../libraries/RelationshipLibrary.sol";
import "../relationship/AbstractRelationshipManager.sol";

/**
 * @title Abstract contract template for milestone relationship management.
 * @author Elijah Hampton
 */
abstract contract IMilestoneRelationshipManager is AbstractRelationshipManager {
    /**
     * @notice Initializes the relationship
     * @param _relationshipID The id of the relationship to access
     * @param _escrow Address of the escrow to process relationship funds
     * @param _valuePtr Address of the token used as medium of exchange
     * @param _employer Address of employer (The tx sender)
     * @param _taskMetadataPtr IPFS hash of the relationship metadata
     * @param _milestoneMetadataPtr IPFS hash of the relationship milestone metadata
     */
    function initializeContract(
        uint256 _relationshipID,
        address _escrow,
        address _valuePtr,
        address _employer,
        string calldata _taskMetadataPtr,
        string memory _milestoneMetadataPtr
    ) external virtual;
}
