// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Evaluation {
    struct EvaluationState {
        string industry;
        uint256 industrylevel;
        uint256 reputation;
    }

    enum WorkRelationshipState { 
        UNCLAIMED,
        PENDING,
        PENDING_DISPUTE,
        CANCELLED,
        COMPLETED,
        EVALUATING,
        CLAIMED
    }
}