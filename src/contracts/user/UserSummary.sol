// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interface/IUserSummary.sol";
import "../libraries/RelationshipLibrary.sol";

/**
 * Deprecated
 */
contract UserSummary is IUserSummary {
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

    function modifyExternalReputation(int256 _amount, Persona _persona) external override onlyWhitelistedReputationModule {
        require(uint256(_persona) == uint256(Persona.Employer) || uint256(_persona) == uint256(Persona.Worker));

        if (_persona == Persona.Employer) {
            employerDescription.externalReputationModuleToReputation[msg.sender] += _amount;
        } else {
            workerDescription.externalReputationModuleToReputation[msg.sender] += _amount;
        }
    }
}

