// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./UserSummary.sol";

/**
 * Deprecated
 */
contract UserSummaryFactory {
    event UserSummaryCreated(address indexed _userSummary, uint256 indexed index, address indexed universalAddress);
    UserSummary[] public userSummaries;

    function _createUserSummary(address _universalAddress) internal returns(address) {
        UserSummary userSummary = new UserSummary(universalAddress);
        userSummaries.push(userSummary);

        emit UserSummaryCreated(address(userSummary), userSummaries.length, _universalAddress);
        return address(userSummary);
    }
}
