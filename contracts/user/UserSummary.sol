// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./interface/IUserSummary.sol";
import "../libraries/Evaluation.sol";
import "../libraries/Relationship.sol";
import "../exchange/WorkRelationship.sol";
import "../market/Market.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

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
        require(relationship.owner() == owner || relationship.worker() == owner, 
            "User must be the employer or worker of this relationship");

        //require relationship to be currently disputed (4) or approved (5)
        require(relationship.contractStatus() == Relationship.ContractStatus.Approved || relationship.contractStatus() == Relationship.ContractStatus.Disputed);

        //TODO: Refactor - perhaps we need to check if the specific market contains this relationship as well
       // Market market = Market(_market); 
        //require the market has a relationship created by this owner
        //require(market.relationshipsToOwner[_relationship] == owner());
        _;
    }

    constructor(address universalAddress) {
        owner = universalAddress;
        universalAddress = universalAddress;
    }

    function evaluateUser(Evaluation.EvaluationState memory evaluationState, address market) external override view returns(bool) {
        require(owner != address(0));

        if (workerDescription.universalReputation >= workerDescription.universalReputation 
        && workerDescription.marketToReputation[evaluationState.market] >= evaluationState.marketReputation) {
            return true;
        } else {
            return false;
        }
    }

    function increaseReputation(address _relationship, uint8 _amount) 
    external
    onlyFromRelationshipCaller(_relationship) {
        //increase reputation
        uint256 updatedUniversalReputation = SafeMath.add(workerDescription.universalReputation, 1);
        workerDescription.universalReputation = SafeCast.toUint8(updatedUniversalReputation);

        uint256 updatedMarketReputation = SafeMath.add(workerDescription.marketToReputation[msg.sender], _amount);
        workerDescription.marketToReputation[msg.sender] = SafeCast.toUint8(updatedMarketReputation);
    }

    function decreaseReputation(address _relationship, uint8 _amount) 
    external
    onlyFromRelationshipCaller(_relationship) {
        //decrease reputation
        uint256 updatedUniversalReputation = SafeMath.sub(workerDescription.universalReputation, 1);
        workerDescription.universalReputation = SafeCast.toUint8(updatedUniversalReputation);

        uint256 updatedMarketReputation = SafeMath.sub(workerDescription.marketToReputation[msg.sender], _amount);
        workerDescription.marketToReputation[msg.sender] = SafeCast.toUint8(updatedMarketReputation);
    }

    function increaseSuccessfulPayout(address _relationship) 
    external
    onlyFromRelationshipCaller(_relationship) {
        //increase successful payout
        employerDescription.numSuccessfulPayouts = SafeMath.add(employerDescription.numSuccessfulPayouts, 1);
    }

    function decreaseSuccessfulPayout(address _relationship) 
    external
    onlyFromRelationshipCaller(_relationship) {
        //decrease successful payout
        employerDescription.numSuccessfulPayouts = SafeMath.sub(employerDescription.numSuccessfulPayouts, 1);
    }
    
    function increaseDisputeCount(address _relationship, uint8 _amount) 
    external
    onlyFromRelationshipCaller(_relationship) {
        //increase dispute count
        employerDescription.numDisputes = SafeMath.add(employerDescription.numDisputes, 1);
    }

    function decreaseDisputeCount(address _relationship, uint8 _amount) 
    external
    onlyFromRelationshipCaller(_relationship) {
        //decrease dispute count
        employerDescription.numDisputes = SafeMath.sub(employerDescription.numDisputes, 1);
    }

    function getBadConsistencyCount() external returns(uint8) {
        return workerDescription.badConsistencyCount;
    }

    function setBadConsistencyCount(uint8 amount) external {
        workerDescription.badConsistencyCount = amount;
    }
}

