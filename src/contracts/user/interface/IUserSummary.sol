// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUserSummary {
    struct Profile {}
    struct Expertise {}
    struct Reputation {}
    struct Activity {}

    function getUserProfile() external view returns(uint);
    function getUserExpertise() external view returns(uint);
    function getUserReputation() external view returns(uint);
    function getUserActivity() external view returns(uint);
}