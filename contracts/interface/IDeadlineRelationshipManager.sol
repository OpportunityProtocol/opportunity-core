// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

function initializeContract(
    uint256 calldata _relationshipID,
    address calldata _escrow,
    address calldata _valuePtr,
    address calldata _employer,
    string calldata _taskMetadataPtr,
    uint256 calldata _deadline
) external virtual;
