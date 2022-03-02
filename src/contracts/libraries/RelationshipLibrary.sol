// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interface/IRelationshipManager.sol";

library RelationshipLibrary {
    /**
     * @dev Structure of a Relationship
     */
    struct Relationship {
        address valuePtr;
        uint256 relationshipID;
        address escrow;
        uint256 marketPtr;
        address employer;
        address worker;
        string taskMetadataPtr;
        ContractStatus contractStatus;
        ContractOwnership contractOwnership;
        ContractPayoutType contractPayoutType;
        uint256 wad;
        uint256 acceptanceTimestamp;
        uint256 resolutionTimestamp;
    }
    struct Market {
        string marketName;
        uint256 marketID;
        address relationshipManager;
        uint256[] relationships;
        address valuePtr;
        address[] participants;
    }

    struct RelationshipReviewBlacklistCheck {
        bool employerReviewed;
        bool workerReviewed;
    }

    enum Persona {
        Employer,
        Worker
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

    enum ContractPayoutType {
        Flat,
        Milestone,
        Deadline
    }
}
