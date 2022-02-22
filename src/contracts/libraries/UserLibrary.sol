// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interface/IRelationshipManager.sol";

library UserLibrary {

    /**
     */
    struct EmployerDescription {
        mapping(uint256 => mapping(uint256 => bytes32)) marketsToRelationshipsToReviews;
    }

    /**
     * @notice Holds data for a user's worker behavior
     */
    struct WorkerDescription {
        mapping(uint256 => mapping(uint256 => bytes32)) marketsToRelationshipsToReviews;
    }

    /**
     * @dev Structure of a Relationship
     */
    struct UserSummary {
        uint256 userID;
        uint256 registrationTimestamp;
        address trueIdentification;
        bytes32[] reviews;
        EmployerDescription employerDescription;
        WorkerDescription workerDescription;
        bool isRegistered;
    }

    enum Persona {
        Employer,
        Worker
    }
}
