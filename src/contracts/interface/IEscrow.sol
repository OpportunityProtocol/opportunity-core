// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IEscrow {
function initialize(uint256 _relationshipID, string calldata _metaevidence) external;
function releaseFunds(uint256 _amount, uint256 _relationshipID) external;
function surrenderFunds(uint256 _relationshipID) external;
}