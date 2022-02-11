// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

library RelationshipLibrary {
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

    struct Milestone {
        string[] milestoneMetadataPtrs;
    }

    enum ContractOwnership {
        Unclaimed,
        Pending,
        Claimed
    }

    enum ContractStatus {
        AwaitingWorker,
        AwaitingWorkerApproval,
        AwaitingResolution,
        Resolved,
        PendingDispute,
        Disputed
    }
}
