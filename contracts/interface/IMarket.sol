// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract IMarket {
    event RelationshipCreated(address indexed owner, address indexed relationship, address indexed marketAddress);

    function createRelationship(address _worker, string _taskMetadataPtr);
}