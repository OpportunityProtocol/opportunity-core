// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUserSummary {
    struct Profile {
        string[] skills;
        string profession;
        string digitalSignature;
        uint8 activityLevel;
    }

    struct TaskGeneralDescription {
        uint256 taskCompleted;
    }

    function getUserProfile() external view returns(string[] memory, string memory, string memory, uint8);
    function signProfile() external;
    function updateProfile(Profile memory updatedProfile) external;
}