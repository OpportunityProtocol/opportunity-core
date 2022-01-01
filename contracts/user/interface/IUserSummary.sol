// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../../libraries/Evaluation.sol";
import "../../libraries/User.sol";
import "../../libraries/StringUtils.sol";

interface IUserSummary {
    address public owner;
    uint256 contractsEntered;
    uint256 contractsCompleted;
    uint256 universalReputation;
    mapping(address => uint256) marketsToReputation;
}