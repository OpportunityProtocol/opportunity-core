// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./UserSummary.sol";

contract UserSummaryFactory {
    constructor() {}

    event UserCreated(UserSummary _userSummary, uint256 index);

    UserSummary[] public userSummaries;

    function createUserSummary(string memory _civicID) external {
        UserSummary userSummary = new UserSummary(_civicID);
        emit UserCreated(userSummary, userSummaries.length);
        userSummaries.push(userSummary);
    }
}
