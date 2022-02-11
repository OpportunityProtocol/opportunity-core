// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


interface IUserSummary {
    enum Persona {
        Employer,
        Worker
    }

    event UserSummaryUpdate(address universalAddress);
    struct EmployerDescription {
        mapping(address => int256) externalReputationModuleToReputation;
    }
    struct WorkerDescription {
        mapping(address => int256) externalReputationModuleToReputation;
    }

    function modifyReputationModulePermissions(address _module, bool _whitelisted) external;
    function modifyExternalReputation(int256 _amount, Persona _persona) external;
}