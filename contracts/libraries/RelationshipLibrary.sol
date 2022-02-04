pragma solidity 0.8.7;

library RelationshipLibrary {
        enum ContractStatus {
        AwaitingWorker,
        AwaitingWorkerApproval,
        AwaitingReview,
        Approved,
        Reclaimed,
        Disputed
    }
}