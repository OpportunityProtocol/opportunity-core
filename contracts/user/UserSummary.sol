// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./interface/IUserSummary.sol";
import "../libraries/Evaluation.sol";
import "@openzeppelin/contracts/SafeMath.sol";

contract UserSummary is IUserSummary {

    event UserSummaryUpdate(address universalAddress);

    address public owner;
    address public universalAddress;

    WorkerDescription public workerDescription;
    EmployerDescription public employerDescription;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    modifier onlyFromRelationshipCaller(address _relationship) {
        require(msg.sender != address(0), "The market caller must not be a null address");
        WorkRelationship relationship = WorkRelationship(_relationship);
        //require that user is employer or worker of this relationship
        require(relationship.owner() == owner || relationship.worker() == worker, 
            "User must be the employer or worker of this relationship");

        //require relationship to be currently disputed (4) or approved (5)
        require(relationship.contractStatus() == 4 || relationship.contractStatus() == 5);

        Market market = Market(_market);
        //require the market has a relationship created by this owner
        require(market.relationshipsToOwner[_relationship] == owner());
    }

    constructor() {
        owner = msg.sender;
        universalAddress = msg.sender;
    }

    function evaluateUser(Evaluation.EvaluationState memory evaluationState, address market) external override view returns(bool) {
        require(owner != address(0));

        if (workerDescription.universalReputation >= workerDescription.universalReputation 
        && workerDescription.marketsToReputation[evaluationState.market] >= evaluationState.marketReputation) {
            return true;
        } else {
            return false;
        }
    }

    function increaseReputation(address _relationship, uint8 _amount) 
    external
    onlyFromRelationshipCaller(_relationship) {
        //increase reputation
        workerDescription.universalReputation = add(workerDescription.universalReputation, 1);
        workerDescription.marketToReputation[msg.sender] = add(workerDescription.marketToReputation[msg.sender], _amount);
    }

    function decreaseReputation(address _relationship, uint8 _amount) 
    external
    onlyFromRelationshipCaller(_relationship) {
        //decrease reputation
        workerDescription.universalReputation = sub(workerDescription.universalReputation, 1);
        workerDescription.marketToReputation[msg.sender] = sub(workerDescription.marketToReputation[msg.sender], _amount);
    }

    function increaseSuccessfulPayout(address _relationship) 
    external
    onlyFromRelationshipCaller(_relationship) {
        //increase successful payout
        employerDescription.numSuccessfulPayouts = add(employerDescription.numSuccessfulPayouts, 1);
    }

    function decreaseSuccessfulPayout(address _relationship) 
    external
    onlyFromRelationshipCaller(_relationship) {
        //decrease successful payout
        employerDescription.numSuccessfulPayouts = sub(employerDescription.numSuccessfulPayouts, 1);
    }
    
    function increaseDisputeCount(address _relationship, uint8 _amount) 
    external
    onlyFromRelationshipCaller(_relationship) {
        //increase dispute count
        employerDescription.numDisputes = add(employerDescription.numDisputes, 1);
    }

    function decreaseDisputeCount(address _relationship, uint8 _amount) 
    external
    onlyFromRelationshhipCaller(_relationship) {
        //decrease dispute count
        employerDescription.numDisputes = sub(employerDescription.numDisputes, 1);
    }
}
