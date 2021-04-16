// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUserSummary {
    struct Profile {
        string[] skills;
        string profession;
        string digitalSignature;
        string activityLevel;
    }

    struct TaskGeneralDescription {
        mapping(address => string) task;
        mapping(address => uint) taskEvaluation;
    }

    function getUserProfile() external view returns(uint);
    function getUserExpertise() external view returns(uint);
    function getUserReputation() external view returns(uint);
    function getUserActivity() external view returns(uint);
}