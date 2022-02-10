pragma solidity 0.8.7;

library RelationshipLibrary {
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

    struct Milestone {
        string milestoneMetadataPtr;
        bool completed;
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
