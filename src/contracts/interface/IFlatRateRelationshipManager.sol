// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../relationship/AbstractRelationshipManager.sol";

abstract contract IFlatRateRelationshipManager is AbstractRelationshipManager {
function initializeContract(
    uint256 _relationshipID,
    address _escrow,
    address _valuePtr,
    address _employer,
    string  calldata _taskMetadataPtr
) external virtual;
}
