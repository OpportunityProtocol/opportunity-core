// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./UserSummary.sol";

/**
 * Factory for creating user summary contracts
 */
contract UserSummaryFactory {
    event UserSummaryCreated(address indexed _userSummary, uint256 indexed index, address indexed universalAddress);
    UserSummary[] public _userSummaries;

    /**
     * createUserSummary
     * Creates a user summary contract based on a wallet address
     * @param universalAddress The wallet address of the user
     @ @return Returns the address of the user summary created
     */
    function _createUserSummary(address universalAddress) private returns(address) {
        UserSummary userSummary = new UserSummary(universalAddress);
        _userSummaries.push(userSummary);

        emit UserSummaryCreated(address(userSummary), _userSummaries.length, universalAddress);
        return address(userSummary);
    }
}
