// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../relationship/AbstractRelationshipManager.sol";
abstract contract IDeadlineRelationshipManager is AbstractRelationshipManager {
    function initializeContract(
        uint256 _relationshipID,
        address _escrow,
        address _valuePtr,
        address _employer,
        string calldata _taskMetadataPtr,
        uint256  _deadline
    ) external virtual;
}
