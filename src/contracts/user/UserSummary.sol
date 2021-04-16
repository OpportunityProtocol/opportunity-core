// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interface/IUserSummary.sol";

contract UserSummary is IUserSummary {
    address private _userUniversalAddress;
    mapping(string => address) private _userTaskList;
    Profile private _userProfile;
    Expertise private _userExpertise;
    Reputation private _userReputation;
    Activity private _userActivity;


    constructor() {}

    function getUserProfile() external view override returns(uint) {return 1;}
    function getUserExpertise() external view override returns(uint) {return 1;}
    function getUserReputation() external view override returns(uint) {return 1;}
    function getUserActivity() external view override returns(uint) {return 1;}
}