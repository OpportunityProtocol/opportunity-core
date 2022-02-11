// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../libraries/RelationshipLibrary.sol";

interface IMarket {
    event RelationshipCreated(address indexed owner, address indexed relationship, address indexed marketAddress);

    function createFlatRateContract(address _escrow, address _valuePtr, string calldata _taskMetadataPtr) external;
    function createMilestoneContract(address _escrow, address _valuePtr, string calldata _taskMetadataPtr, string memory _milestoneMetadataPtr) external;
    function createDeadlineContract(address _escrow, address _valuePtr, string calldata _taskMetadataPtr, uint256 _deadline) external;
}