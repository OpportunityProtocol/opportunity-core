// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./UserSummary.sol";

contract UserSummaryFactory {
    event UserSummaryCreated(UserSummary indexed _userSummary, uint256 indexed index);
    UserSummary[] private _userSummaries;

    constructor() {}

    /**
     * Creates a user summary contract for each user based on their civic ID.
     */
     function createUserSummary(string memory civicID) external returns(address) {
        UserSummary userSummary = new UserSummary(civicID);
        emit UserSummaryCreated(userSummary, _userSummaries.length);
        _userSummaries.push(userSummary);

        address userSummaryAddress = userSummary.getContractAddress();
        return userSummaryAddress;
    }

    /**
     *
     */
     function getNumUserSummaries() public view returns (uint256) {
         return _userSummaries.length;
     }
}
