// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./interface/IUserSummary.sol";
import "../libraries/Evaluation.sol";
import "../libraries/Relationship.sol";
import "../libraries/User.sol";
import "../exchange/WorkRelationship.sol";
import "./UserRegistration.sol";
import "../market/Market.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract UserSummary is IUserSummary {

    event UserSummaryUpdate(address universalAddress);

    address public owner;
    EmployerDescription employerDescription;
    WorkerDescription workerDescription;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    modifier onlyFromRelationshipCaller(address _relationship) {
        require(msg.sender != address(0), "The market caller must not be a null address");
        WorkRelationship relationship = WorkRelationship(_relationship);
        //require that user is employer or worker of this relationship
        require(relationship.owner() == owner || relationship.worker() == owner, 
            "User must be the employer or worker of this relationship");

        //require relationship to be currently approved (5)
        require(relationship.contractStatus() == Relationship.ContractStatus.Approved 
        || relationship.contractStatus() == Relationship.ContractStatus.AwaitingSubmission, "This function can only be called by a relationship in the approved or awaiting submission state.");

        //check to see if this relationship is a valid relationship in markets
        Market market = Market(relationship.market()); 
        for (uint256 i = 0; i < market.getNumRelationshipsCreated(); i++) {
            if (market.getWorkRelationships()[i] == _relationship) {
                break;
            }

            revert();
        }
        _;
    }

    constructor(address universalAddress) {
        owner = universalAddress;
    }

    function increaseContractsCompleted(User.UserInterface userInterface) 
    external
    onlyFromRelationshipCaller(msg.sender) {
        if (userInterface == User.UserInterface.Worker) {
            workerDescription.contractsCompleted++;
        } else if (userInterface == User.UserInterface.Employer) {
            employerDescription.contractsCompleted++;
        } else {}
    }

    function decreaseContractCompleted(User.UserInterface userInterface) 
    external
    onlyFromRelationshipCaller(msg.sender) {
        if (userInterface == User.UserInterface.Worker) {
            workerDescription.contractsCompleted--;
        } else if (userInterface == User.UserInterface.Employer) {
            employerDescription.contractsCompleted--;
        } else {}
    }

    function increaseReputation(User.UserInterface userInterface) 
    external
    onlyFromRelationshipCaller(msg.sender) {
        if (userInterface == User.UserInterface.Worker) {
            workerDescription.universalReputation++;
        } else if (userInterface == User.UserInterface.Employer) {
            employerDescription.universalReputation++;
        } else {}
    }

    function decreaseReputation(User.UserInterface userInterface) 
    external
    onlyFromRelationshipCaller(msg.sender) {
        if (userInterface == User.UserInterface.Worker) {
            workerDescription.universalReputation--;
        } else if (userInterface == User.UserInterface.Employer) {
            employerDescription.universalReputation--;
        } else {}
    }
    

    function increaseContractsEntered(User.UserInterface userInterface)
    external
    onlyFromRelationshipCaller(msg.sender)
    {
        if (userInterface == User.UserInterface.Worker) {
            workerDescription.contractsEntered++;
        } else if (userInterface == User.UserInterface.Employer) {
            employerDescription.contractsEntered++;
        } else {}
    }
    
    function decreaseContractsEntered(User.UserInterface userInterface)
    external
    onlyFromRelationshipCaller(msg.sender)
    {
        if (userInterface == User.UserInterface.Worker) {
            workerDescription.contractsEntered--;
        } else if (userInterface == User.UserInterface.Employer) {
            employerDescription.contractsEntered--;
        } else {}
    }

    function increaseTips(uint value)
    external
    onlyFromRelationshipCaller(msg.sender) {
        workerDescription.tipsEarned += value;
    }
}

