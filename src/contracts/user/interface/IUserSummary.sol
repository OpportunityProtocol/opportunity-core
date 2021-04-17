// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUserSummary {
    struct Profile {
        string[] skills;
        string profession;
        string digitalSignature;
        uint8 activityLevel;
    }

    struct WorkerTaskGeneralDescription {
        uint256 taskCompleted;

        // Mapping of industry ids to evaluations
        mapping(string => uint256) industryEvaluation;

        // Mapping of WorkRelationship IDs to WorkExchanges.
        mapping(uint256 => address) relationshipExchanges;
    }

    struct RequesterTaskGeneralDescription {
        uint256 taskAssigned;

         // Mapping of WorkRelationship IDs to WorkExchanges.
        mapping(uint256 => address) relationshipExchanges;
    }

    function getUserProfile() external view returns(string[] memory, string memory, string memory, uint8);
    function signProfile() external;
    function updateProfile(Profile memory updatedProfile) external;
}