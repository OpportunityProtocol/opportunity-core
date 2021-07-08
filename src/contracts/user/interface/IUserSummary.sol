// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../../libraries/Evaluation.sol";
import "../../libraries/User.sol";
import "../../libraries/StringUtils.sol";

interface IUserSummary {
    struct Profile {
        string[] skills;
        string profession;
        uint8 activityLevel;
    }

    struct WorkerTaskGeneralDescription {
        uint256 taskCompleted;

        // Mapping of industry ids to evaluations
        mapping(string => uint256) industryEvaluation;

        // Mapping of WorkRelationship to status
        mapping(address => string) relationshipExchanges;
    }

    struct RequesterTaskGeneralDescription {
        uint256 taskAssigned;

         // Mapping of WorkRelationship IDs to current WorkExchanges.
        mapping(uint256 => address) relationshipExchanges;
    }

    function evaluateUser(Evaluation.EvaluationState memory evaluationState) external returns(bool);
    function getUserProfile() external view returns(string[] memory, string memory, uint8);
    function updateProfile(Profile memory updatedProfile, address universalAddress) external;
}