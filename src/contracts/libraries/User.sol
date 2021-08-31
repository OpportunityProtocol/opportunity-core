// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./StringUtils.sol";

library User {
       modifier onlyAuthenticatedUser(string storage uniqueID, string storage uniqueHash) {
        require(StringUtils.equal(uniqueID, uniqueHash));
        _;
    }
}