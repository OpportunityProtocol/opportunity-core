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
        require(owner == msg.sender, "Only the owner of this contract can call this function.");
        _;
    }

    modifier onlyFromApprovedRelationshipCaller(address _relationship) {
        require(msg.sender != address(0), "The market caller must not be a null address");
        WorkRelationship relationship = WorkRelationship(_relationship);
    
        require(relationship.owner() == owner || relationship.worker() == owner, 
            "User must be the employer or worker of this relationship");

        require(relationship.contractStatus() == Relationship.ContractStatus.Approved, 
            "This function can only be called by a relationship in the approved state.");

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

    modifier onlyFromAwaitingSubmissionRelationshipCaller(address _relationship) {
        require(msg.sender != address(0), "The market caller must not be a null address");
        WorkRelationship relationship = WorkRelationship(_relationship);

        require(relationship.owner() == owner || relationship.worker() == owner, 
            "User must be the employer or worker of this relationship");

        require(relationship.contractStatus() == Relationship.ContractStatus.AwaitingSubmission, 
            "This function can only be called by a relationship in the approved or awaiting submission state.");

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

    /**
     * increaseContractsCompleted
     * Increases the number of contracts completed for this user
     * @param userInterface The current interface of the user
     */
    function increaseContractsCompleted(User.UserInterface userInterface) 
    external
    onlyFromApprovedRelationshipCaller(msg.sender) {
        if (userInterface == User.UserInterface.Worker) {
            workerDescription.contractsCompleted++;
        } else if (userInterface == User.UserInterface.Employer) {
            employerDescription.contractsCompleted++;
        } else {}
    }

    /**
     * decreaseContractsCompleted
     * Decreases the number of contracts completed for this user
     * @param userInterface The current interface of the user
     */
    function decreaseContractCompleted(User.UserInterface userInterface) 
    external
    onlyFromApprovedRelationshipCaller(msg.sender) {
        if (userInterface == User.UserInterface.Worker) {
            workerDescription.contractsCompleted--;
        } else if (userInterface == User.UserInterface.Employer) {
            employerDescription.contractsCompleted--;
        } else {}
    }

    /**
     * increaseReputation
     * Increases the reputation completed for this user
     * @param userInterface The current interface of the user
     */
    function increaseReputation(User.UserInterface userInterface) 
    external
    onlyFromApprovedRelationshipCaller(msg.sender) {
        if (userInterface == User.UserInterface.Worker) {
            workerDescription.universalReputation++;
        } else if (userInterface == User.UserInterface.Employer) {
            employerDescription.universalReputation++;
        } else {}
    }

    /**
     * decreaseReputation
     * Decreases the reputation completed for this user
     * @param userInterface The current interface of the user
     */
    function decreaseReputation(User.UserInterface userInterface) 
    external
    onlyFromApprovedRelationshipCaller(msg.sender) {
        if (userInterface == User.UserInterface.Worker) {
            workerDescription.universalReputation--;
        } else if (userInterface == User.UserInterface.Employer) {
            employerDescription.universalReputation--;
        } else {}
    }
    
    /**
     * increaseContractsEntered
     * Increases the number of contracts entered for this user
     * @param userInterface The current interface of the user
     */
    function increaseContractsEntered(User.UserInterface userInterface)
    external
    onlyFromAwaitingSubmissionRelationshipCaller(msg.sender)
    {
        if (userInterface == User.UserInterface.Worker) {
            workerDescription.contractsEntered++;
        } else if (userInterface == User.UserInterface.Employer) {
            employerDescription.contractsEntered++;
        } else {}
    }
    
    /**
     * decreaseContractsEntered
     * Decreases the number of contracts entered for this user
     * @param userInterface The current interface of the user
     */
    function decreaseContractsEntered(User.UserInterface userInterface)
    external
    onlyFromAwaitingSubmissionRelationshipCaller(msg.sender)
    {
        if (userInterface == User.UserInterface.Worker) {
            workerDescription.contractsEntered--;
        } else if (userInterface == User.UserInterface.Employer) {
            employerDescription.contractsEntered--;
        } else {}
    }

    /**
     * Increases the value of tips this user has receieved
     * @param value The value of the tip receieved by the user
     */
    function increaseTips(uint value)
    external
    onlyFromApprovedRelationshipCaller(msg.sender) {
        workerDescription.tipsEarned += value;
    }
}

