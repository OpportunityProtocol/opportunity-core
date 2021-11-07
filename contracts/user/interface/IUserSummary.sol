// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../../libraries/Evaluation.sol";
import "../../libraries/User.sol";
import "../../libraries/StringUtils.sol";

interface IUserSummary {
    struct WorkerDescription {
        uint256 universalReputation;
        uint8 badConsistencyCount;

        //mapping of markets to reputation
        mapping(address => uint8) marketToReputation;

        // Mapping of markets to evaluations
        mapping(address => uint256) marketsToEvaluations;
    }

    struct EmployerDescription {
        uint256 numSuccessfulPayouts;
        uint256 numDisputes;

         // Mapping of relationships to status.
        mapping(address => uint8) relationshipExchanges;
    }

    function evaluateUser(Evaluation.EvaluationState memory evaluationState, address market) external returns(bool);

}