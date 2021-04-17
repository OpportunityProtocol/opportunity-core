// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interface/IUserSummary.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UserSummary is IUserSummary, Ownable {
    string private _civicID;
    uint256 private _userReputation;
    mapping(string => address) private _userTaskList;

    Profile private _userProfile;
    TaskGeneralDescription private _userTaskGeneralDescription;

    constructor(string memory _civicIDIn) {
        _civicID = _civicIDIn;
        _userReputation = 1;
        _userProfile.profession = "";
        _userProfile.activityLevel = 0;

        _userTaskGeneralDescription.taskCompleted = 0;
    }

    /**
     *
     */
    function getUserProfile()
        external
        view
        override
        returns (
            string[] memory,
            string memory,
            string memory,
            uint8
        )
    {
        return (
            _userProfile.skills,
            _userProfile.profession,
            _userProfile.digitalSignature,
            _userProfile.activityLevel
        );
    }

    /**
     *
     */
    function signProfile() external override {}

    /**
     *
     */
    function updateProfile(Profile memory updatedProfile) external override {}
}