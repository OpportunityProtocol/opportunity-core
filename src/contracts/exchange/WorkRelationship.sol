// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./WorkExchange.sol";
import "../user/UserSummary.sol";
import "../libraries/Evaluation.sol";
import "../libraries/Market.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WorkRelationship is Ownable {
    event RelationshipCreated(string indexed _owner, Market.MarketUtil.MarketType indexed _marketType, address indexed _relationship);
    event RelationshipDisabled(string indexed _owner, Market.MarketUtil.MarketType indexed _marketType, address indexed _relationship);

    // Status of the current contract
    string private _contractStatus;
    // Work evaluation
    string private _evaluation;
    // Task address
    address private _taskAddress;
    // Task solution pointer
    string private _taskPointer;
    // Address of the current worker
    address private _currentWorker;
    // Address of current work exchange
    address private _currentWorkExchange;
    // Type of market (default or created)
    string private _marketType;

    constructor(Market.MarketUtil.MarketType _marketType) {
        bool passesEvaluation = checkWorkerEvaluation(newWorker, evaluationState);
        require(passesEvaluation == true);

        RelationshipCreated(_owner, _marketType, address(this));
    }

    function getWorkerProfile() public view {
        return UserSummary(_currentWorker).getUserProfile();
    }
    
    function getRequesterProfile() public view {
        return UserSummary(_owner).getUserProfile();
    }

    function createWorkExchange(address payable workerBeneficiary, bool isTimeLocked) external {
        bool passesEvaluation = checkWorkerEvaluation(newWorker, evaluationState);
        require(passesEvaluation == true);

        WorkExchange workExchange = new WorkExchange(_owner, workerBeneficiary, isTimeLocked);
        setCurrentWorker(workerBeneficiary);
        setCurrentWorkExchange(workExchange.getContractAddress());
    }

    function checkWorkerEvaluation(address workerUniversalAddress, Evaluation.EvaluationState memory evaluationState) internal returns(bool) {
        bool passesEvaluation = UserSummary(workerUniversalAddress).evaluateUser(evaluationState);
        return passesEvaluation;
    }

    function setCurrentWorker(address newWorker) private {
        _currentWorker = newWorker;
    }

    function setCurrentWorkExchange(address workExchange) private {
        _currentWorkExchange = workExchange;
    }

    function defaultWorker() private {
        setCurrentWorker(address(0));
    }

    function disableWorkRelationship() public onlyOwner {
        require(_contractStatus == Evaluation.WorkRelationshipState.COMPLETED || _contractStatus == Evaluation.WorkRelationshipState.COMPLETED);
        RelationshipDisabled(_owner, _marketType, address(this));
        selfdestruct();
    }
}