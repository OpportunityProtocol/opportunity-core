// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title Reputation module interface for UserSummary contracts
 * @author Elijah Hampton
 */
interface IReputationModule {

/**
 * @notice Modify a user's reputation by a desired amount
 * @dev This function should only alter a user's reputation for a specific address (msg.sender)
 */
function modifyReputation(uint256 _amount) external;

/**
 * @notice Modify a user's deragtory marks by a desired amount
 * @dev This function should only alter a user's deragatory marks for a specific address (msg.sender)
 */
function modifyDeragatoryMarks(uint256 _amount) external;
}