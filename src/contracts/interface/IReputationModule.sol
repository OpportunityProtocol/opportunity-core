// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IReputationModule {
function increaseReputation(uint256 _amount) external;
function decreaseReputation(uint256 _amount) external;
function addDeragtoryMarks(uint256 _amount) external;
function removeDeragtoryMarks(uint256 _amount) external;
}