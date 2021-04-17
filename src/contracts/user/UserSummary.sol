// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interface/IUserSummary.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UserSummary is IUserSummary, Ownable {
    string private _civicID;
    uint256 private _userReputation;

    Profile private _userProfile;
    WorkerTaskGeneralDescription private _workerTaskGeneralDescription;
    RequesterTaskGeneralDescription private _requesterTaskGeneralDescription;

    /**
     *
     */
    function signProfile(string memory signature) external override onlyOwner {
        _userProfile.digitalSignature = signature;
    }

    constructor(string memory _civicIDIn, string memory signature) {
        _civicID = _civicIDIn;
        _userReputation = 1;
        _userProfile.profession = "";
        _userProfile.activityLevel = 0;

        _workerTaskGeneralDescription.taskCompleted = 0;
        _requesterTaskGeneralDescription.taskAssigned = 0;

        signProfile(signature);
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
    function updateProfile(Profile memory updatedProfile) external override {}
}
