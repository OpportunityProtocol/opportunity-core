// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../libraries/RelationshipLibrary.sol";
import "../interface/IMarket.sol";
import "../interface/IFlatRateRelationshipManager.sol";
import "../interface/IMilestoneRelationshipManager.sol";
import "../interface/IDeadlineRelationshipManager.sol";

contract Market is IMarket {
    string marketName;
    IFlatRateRelationshipManager frManager;
    IMilestoneRelationshipManager mManager;
    IDeadlineRelationshipManager deadlineManager;

    uint256[] public relationships;
    mapping(uint256 => address) public flatRateRelationshipIDToAddress;
    mapping(uint256 => address) public milestoneRelationshipIDToAddress;
    mapping(uint256 => address) public deadlineRelationshipIDToAddress;
    
    constructor(
        string memory _marketName,
        address _flatRateRelationshipManager,
        address _milestoneRelationshipManager,
        address _deadlineRelationshipManager
    ) {
        marketName = _marketName;
        frManager = IFlatRateRelationshipManager(_flatRateRelationshipManager);
        mManager = IMilestoneRelationshipManager(_milestoneRelationshipManager);
        deadlineManager = IDeadlineRelationshipManager(_deadlineRelationshipManager);
    }

    function createFlatRateContract(address _escrow, address _valuePtr, string calldata _taskMetadataPtr) external override {
        relationships.push(relationships.length + 1);
        frManager.initializeContract(relationships.length, _escrow, _valuePtr, msg.sender, _taskMetadataPtr);
    }

    function createMilestoneContract(address _escrow, address _valuePtr, string calldata _taskMetadataPtr, string memory _milestoneMetadataPtr) external override {
        relationships.push(relationships.length + 1);
        mManager.initializeContract(relationships.length, _escrow, _valuePtr, msg.sender, _taskMetadataPtr,  _milestoneMetadataPtr);
    }
    function createDeadlineContract(address _escrow, address _valuePtr, string calldata _taskMetadataPtr, uint256 _deadline) external override {
        relationships.push(relationships.length + 1);
        deadlineManager.initializeContract(relationships.length, _escrow, _valuePtr, msg.sender, _taskMetadataPtr, _deadline);
    }
}
