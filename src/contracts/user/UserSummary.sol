// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interface/IUserSummary.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UserSummary is IUserSummary, Ownable {
    address private _userUniversalAddress;
    uint private _userReputation;
    mapping(string => address) private _userTaskList;

    Profile private _userProfile;
    TaskGeneralDescription private _userTaskGeneralDescription;

    constructor() {
        _userReputation = 1;
    }

    function getUserProfile() external view override returns(uint) {return 1;}
    function getUserExpertise() external view override returns(uint) {return 1;}
    function getUserReputation() external view override returns(uint) {return 1;}
    function getUserActivity() external view override returns(uint) {return 1;}
}