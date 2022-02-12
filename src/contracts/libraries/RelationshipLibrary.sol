// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

library RelationshipLibrary {
    /**
     * @dev Structure of a Relationship
     */
    struct Relationship {
        address valuePtr;
        uint256 relationshipID;
        address escrow;
        address marketPtr;
        address employer;
        address worker;
        string taskMetadataPtr;
        RelationshipLibrary.ContractStatus contractStatus;
        ContractOwnership contractOwnership;
        uint256 wad;
        uint256 acceptanceTimestamp;
    }

    /**
     * @dev Enum representing the states ownership for a relationship
     */
    enum ContractOwnership {
        Unclaimed,
        Pending,
        Claimed
    }

    /**
     * @dev Enum representing the states ownership for a relationship
     */
    enum ContractStatus {
        AwaitingWorker,
        AwaitingWorkerApproval,
        AwaitingResolution,
        Resolved,
        PendingDispute,
        Disputed
    }
}
