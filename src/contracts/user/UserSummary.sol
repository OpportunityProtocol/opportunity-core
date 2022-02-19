// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interface/IUserSummary.sol"; 
import "../libraries/RelationshipLibrary.sol";


/**
 * Deprecated
 */
contract UserSummary is IUserSummary {
    address immutable public owner;
    address immutable public coordinator;
    
    EmployerDescription employerDescription;
    WorkerDescription workerDescription;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyGovernor() {
        require(msg.sender == coordinator, "Only the OpportunityGovernor can invoke this function.");
        _;
    }

    constructor(address _universalAddress, address _coordinator) {
        owner = _universalAddress;
        coordinator = _coordinator;
    }

    function recordReview(bytes32 _reviewHash) onlyGovernor external {
        //
    }
}

