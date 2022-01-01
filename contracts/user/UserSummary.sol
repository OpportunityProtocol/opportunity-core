// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./interface/IUserSummary.sol";
import "../libraries/Evaluation.sol";
import "../libraries/Relationship.sol";
import "../exchange/WorkRelationship.sol";
import "./UserRegistration.sol";
import "../market/Market.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract UserSummary is IUserSummary {

    event UserSummaryUpdate(address universalAddress);
    address public registrar = address(0x31799946e72a44273515556e366e059064Df8ca2);

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
        for (var i = 0; i < market.createdJobs(); i++) {
            if (market.createdJobs()[i] == _relationship) {
                break;
            }

            revert();
        }
        _;
    }

    constructor(address universalAddress) {
        require(msg.sender == registrar);
        owner = universalAddress;
    }

    function increaseContractsCompleted() 
    external
    onlyFromRelationshipCaller(msg.sender) {
        universalReputation++;
        WorkRelationship relationship = WorkRelationship(msg.sender);
        marketToReputation[relationship.market()]++;
    }

    function decreaseContractCompleted() 
    external
    onlyFromRelationshipCaller(msg.sender) {
        universalReputation++;
        WorkRelationship relationship = WorkRelationship(msg.sender);
        marketToReputation[relationship.market()]++;
    }

    function increaseReputation() 
    external
    onlyFromRelationshipCaller(msg.sender) {
        universalReputation++;
        WorkRelationship relationship = WorkRelationship(msg.sender);
        marketToReputation[relationship.market()]++;
    }

    function decreaseReputation() 
    external
    onlyFromRelationshipCaller(msg.sender) {
        universalReputation++;
        WorkRelationship relationship = WorkRelationship(msg.sender);
        marketToReputation[relationship.market()]++;
    }
    

    function increaseContractsEntered()
    external
    onlyFromRelationshipCaller(msg.sender)
    {
        contractsEntered++;
    }
    
    function decreaseContractsEntered()
    external
    onlyFromRelationshipCaller(msg.sender)
    {
        contractsEntered++;
    }

    function increaseTips(uint value)
    external
    onlyFromRelationshipCaller(msg.sender) {
        workerDescription.tipsEarned += value;
    }
}

