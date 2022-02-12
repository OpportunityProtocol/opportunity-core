// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title UserSummary interface
 * @author Elijah Hampton
 */
interface IUserSummary {
    enum Persona {
        Employer,
        Worker
    }

    /**
     * @dev To be emitted upon updating a UserSummary contract
     */
    event UserSummaryUpdate(address universalAddress);

    /**
     * @notice Holds data for a user's employer behavior
     */
    struct EmployerDescription {
        mapping(address => int256) externalReputationModuleToReputation;
    }

    /**
     * @notice Holds data for a user's worker behavior
     */
    struct WorkerDescription {
        mapping(address => int256) externalReputationModuleToReputation;
    }

    /**
     * @notice Allows or denies a reputation module to record reputation for a user
     * @param _module Address of the module to allow or deny permissions
     * @param _whitelisted Permission of the module
     */
    function modifyReputationModulePermissions(
        address _module,
        bool _whitelisted
    ) external;

    /**
     * @notice Allows or denies a reputation module to record reputation for a user
     * @param _module Address of the module to allow or deny permissions
     * @param _whitelisted Permission of the module
     */
    function modifyExternalReputation(int256 _amount, Persona _persona)
        external;
}
