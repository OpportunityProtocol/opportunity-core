// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./WorkExchange.sol";
import "../user/UserSummary.sol";
import "../libraries/Evaluation.sol";
import "../libraries/Market.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WorkRelationship is Ownable {
    event WorkRelationshipCreated(address indexed _owner, address indexed relationship);
    event WorkRelationshipEnded(address indexed owner, address indexed relationship);

    // Status of the current contract
    Evaluation.WorkRelationshipState private _contractStatus;
    // Task solution pointer
    string private _taskPointer = "";

    constructor(address payable newWorker, Evaluation.EvaluationState memory evaluationState, bool isTimeLocked) {
        bool passesEvaluation = checkWorkerEvaluation(newWorker, evaluationState);
        require(passesEvaluation == true);

        this.createWorkExchange(newWorker, isTimeLocked);
        emit WorkRelationshipCreated(owner(), address(this));
    }

    function createWorkExchange(address payable workerBeneficiary, bool isTimeLocked) external {
        WorkExchange workExchange = new WorkExchange(payable(owner()), workerBeneficiary, isTimeLocked);
    }

    function checkWorkerEvaluation(address workerUniversalAddress, Evaluation.EvaluationState memory evaluationState) internal returns(bool) {
        bool passesEvaluation = UserSummary(workerUniversalAddress).evaluateUser(evaluationState);
        return passesEvaluation;
    }

    function disableWorkRelationship() public onlyOwner {
        require(_contractStatus == Evaluation.WorkRelationshipState.COMPLETED || _contractStatus == Evaluation.WorkRelationshipState.COMPLETED);
        emit WorkRelationshipEnded(owner(), address(this));
        //selfdestruct();
    }

    function updateTaskPointer(string memory newTaskPointerHash) external {
        _taskPointer = newTaskPointerHash;
    }

    function getTaskPointer() view external returns(string memory) {
        return _taskPointer;
    }
}