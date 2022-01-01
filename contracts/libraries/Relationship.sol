pragma solidity 0.8.7;

library Relationship {
        enum ContractStatus {
        AwaitingWorker,
        AwaitingWorkerApproval,
        AwaitingSubmission,
        AwaitingReview,
        Approved
    }
}