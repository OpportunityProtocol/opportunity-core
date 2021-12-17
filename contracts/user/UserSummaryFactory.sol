// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./UserSummary.sol";

contract UserSummaryFactory {
    event UserSummaryCreated(address indexed _userSummary, uint256 indexed index, address indexed universalAddress);
    UserSummary[] private _userSummaries;

    function createUserSummary(address universalAddress) external returns(address) {
        UserSummary userSummary = new UserSummary(universalAddress);
        _userSummaries.push(userSummary);

        emit UserSummaryCreated(address(userSummary), _userSummaries.length, universalAddress);
        return address(userSummary);
    }

    function getNumUserSummaries() public view returns (uint256) {
         return _userSummaries.length;
    }
}
