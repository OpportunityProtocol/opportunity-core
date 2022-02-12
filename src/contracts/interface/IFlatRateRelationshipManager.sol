// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../relationship/AbstractRelationshipManager.sol";

/**
 * @title Abstract contract template for flat rate relationship management.
 * @author Elijah Hampton
 */
abstract contract IFlatRateRelationshipManager is AbstractRelationshipManager {
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
        address _escrow,
        address _valuePtr,
        address _employer,
        string calldata _taskMetadataPtr
    ) external virtual;
}
