// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

library Evaluation {
    struct EvaluationState {
        address market;
        uint256 marketReputation;
        uint256 universalReputation;
    }

    enum WorkRelationshipState { 
        UNCLAIMED,
        PENDING,
        CLAIMED
    }

    enum ContractType {
        NORMAL,
        FLASH
    }
}