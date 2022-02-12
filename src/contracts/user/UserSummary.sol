// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interface/IUserSummary.sol";
import "../interface/IReputationModule.sol";
import "../libraries/RelationshipLibrary.sol";


/**
 * Deprecated
 */
contract UserSummary is IUserSummary {
    address immutable public owner;
    EmployerDescription employerDescription;
    WorkerDescription workerDescription;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address universalAddress) {
        owner = universalAddress;
    }
}

