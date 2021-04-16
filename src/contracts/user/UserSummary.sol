// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interface/IUserSummary.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UserSummary is IUserSummary, Ownable {
    string private _userUniversalAddress;
    uint private _userReputation;
    mapping(string => address) private _userTaskList;

    Profile private _userProfile;
    TaskGeneralDescription private _userTaskGeneralDescription;

    constructor(string memory _civicID) {
        _userUniversalAddress = _civicID;
        _userReputation = 1;
    }

    function getUserProfile() external view override returns(string[] memory, string memory, string memory, string memory) {
        return (_userProfile.skills, _userProfile.profession, _userProfile.digitalSignature, _userProfile.activityLevel);
    }
}