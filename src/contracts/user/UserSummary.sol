// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interface/IUserSummary.sol";
import "../interface/IReputationModule.sol":
import "../libraries/RelationshipLibrary.sol";


/**
 * Deprecated
 */
contract UserSummary is IUserSummary, isIReputationModule {
    address immutable public owner;
    EmployerDescription employerDescription;
    WorkerDescription workerDescription;
    mapping(address => bool) reputationModulePermissions;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyWhitelistedReputationModule() {
        require(reputationModulePermissions[msg.sender] == true);
        _;
    }

    constructor(address universalAddress) {
        owner = universalAddress;
    }

    function modifyReputationModulePermissions(address _module, bool _whitelisted) onlyOwner external override {
        reputationModulePermissions[_module] = _whitelisted;
    }
}

