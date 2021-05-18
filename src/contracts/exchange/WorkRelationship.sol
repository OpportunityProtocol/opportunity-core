// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./WorkExchange.sol";
import "../user/UserSummary.sol";
import "../libraries/Evaluation.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WorkRelationship is Ownable {
    event WorkRelationshipCreated(address indexed _owner, address indexed relationship);
    event WorkRelationshipEnded(address indexed owner, address indexed relationship);

    // Status of the current contract
    Evaluation.WorkRelationshipState public _contractStatus;
    address public _workExchangeAddress;
    string public _contractTaskName;
    // Task solution pointer
    string private _taskPointer = "";

    constructor(string memory taskName) {
        _contractTaskName = taskName;
    }

    function assignNewWorker(address payable newWorker, Evaluation.EvaluationState memory evaluationState, bool isTimeLocked) external onlyOwner {
        bool passesEvaluation = checkWorkerEvaluation(newWorker, evaluationState);
        require(passesEvaluation == true);

        this.createWorkExchange(newWorker, isTimeLocked);
        emit WorkRelationshipCreated(owner(), address(this));
    }

    function createWorkExchange(address payable workerBeneficiary, bool isTimeLocked) external onlyOwner {
        WorkExchange workExchange = new WorkExchange(payable(owner()), workerBeneficiary, isTimeLocked);
        _workExchangeAddress = address(workExchange);
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

    function updateTaskPointer(string memory newTaskPointerHash) external onlyOwner {
        _taskPointer = newTaskPointerHash;
    }

    function getTaskPointer() view external returns(string memory) {
        return _taskPointer;
    }
}