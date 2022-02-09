// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract IRelationship {
    event ContractStatusUpdate();
    event ContractOwnershipUpdate();
    event ContractStateUpdate();
    event ExternalContractNotification();

    function updateTaskMetadataPointer(string calldata _newTaskPointerHash) external virtual;
    function assignNewWorker() external virtual;
    function work(bool calldata _accepted) virtual external;
    function releaseJob() external virtual;
    function resolve() external virtual;
    function notifyContract(uint256 _dataOne, bytes32 _dataTwo) external virtual;
}