// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract RelationshipTypes {
    struct Relationship {
        address valuePtr;
        address relationshipID;
        address escrow;
        address marketPtr;
        address employer;
        address worker;
        string taskMetadataPtr;
        RelationshipLibrary.ContractStatus contractStatus;
        ContractState contractState;
        ContractOwnership contractOwnership;
        ContractType contractType;
        uint256 wad;
        uint256 acceptanceTimestamp;
    }
}
