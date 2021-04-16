// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./UserSummary.sol";

contract UserSummaryFactory {
    event UserSummaryCreated(UserSummary indexed _userSummary, uint256 indexed index);
    UserSummary[] private userSummaries;
    
    constructor() {}

    function createUserSummary(string memory indexed _civicID) external {
        UserSummary userSummary = new UserSummary(_civicID);
        emit UserSummaryCreated(userSummary, userSummaries.length);
        userSummaries.push(userSummary);
    }
}
