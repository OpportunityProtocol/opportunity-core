// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../libraries/RelationshipLibrary.sol";
import "../interface/IMarket.sol";
import "../relationship/DeadlineRelationshipManager.sol";

contract Market is IMarket {
    string immutable marketName;
    FlatRateRelationshipManager frManager;
    MilestoneRelationshipManager mManager;
    DeadlineRelationshipManager deadlineManager;
    StreamRelationshipManager streamManager;

    uint256[] public relationships;
    mapping(uint256 => address) public flatRateRelationshipIDToAddress;
    mapping(uint256 => address) public milestoneRelationshipIDToAddress;
    mapping(uint256 => address) public deadlineRelationshipIDToAddress;
    mapping(uint256 => address) public streamRelationshipIDToAddress;
    constructor(
        string calldata _marketName,
        address _flatRateRelationshipManager,
        address _milestoneRelationshipManager,
        address _streamRelationshipManager,
        address _deadlineRelationshipManager
    ) {
        marketName = _marketName;
        frManager = FlatRateRelationshipManager(_flatRateRelationshipManager);
        mManager = MilestoneRelationshipManager(_milestoneRelationshipManager);
        deadlineManager = DeadlineRelationshipManager(_streamRelationshipManager);
        streamManager = StreamRelationshipManager(_deadlineRelationshipManager);
    }

    function createFlatRateContract(address _escrow, address _valuePtr, string calldata _taskMetadataPtr, string memory _extraData) external override {
        frManager.initializeContract(_relationshipID, _escrow, _valuePtr, msg.sender, _taskMetadataPtr, _extraData);
    }

    function createMilestoneContract() external override {
        frManager.initializeContract(_relationshipID, _escrow, _valuePtr, msg.sender, _taskMetadataPtr, _milestones);
    }
    function createDeadlineContract() external override {
         frManager.initializeContract(_relationshipID, _escrow, _valuePtr, msg.sender, _taskMetadataPtr, _deadline);
    }
}
