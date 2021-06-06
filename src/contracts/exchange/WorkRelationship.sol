// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./WorkExchange.sol";
import "../user/UserSummary.sol";
import "../libraries/Evaluation.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WorkRelationship is Ownable {
    event WorkRelationshipCreated(address indexed _owner, address indexed relationship, address indexed marketAddress);
    event WorkRelationshipEnded(address indexed owner, address indexed relationship);

    Evaluation.WorkRelationshipState public _contractStatus;
    address public _workExchangeAddress;
    string public _taskMetadataPointer = "";

    constructor(address marketAddress) {
        _contractStatus = Evaluation.WorkRelationshipState.UNCLAIMED;
        emit WorkRelationshipCreated(owner(), address(this), marketAddress);
    }

    function assignNewWorker(address payable newWorker, Evaluation.EvaluationState memory evaluationState, bool isTimeLocked) external onlyOwner {
        bool passesEvaluation = checkWorkerEvaluation(newWorker, evaluationState);
        require(passesEvaluation == true);

        this.createWorkExchange(newWorker, isTimeLocked);
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
        require(_contractStatus == Evaluation.WorkRelationshipState.COMPLETED);
        emit WorkRelationshipEnded(owner(), address(this));
        //selfdestruct();
    }

     function updateTaskMetadataPointer(string memory newTaskPointerHash) onlyOwner external {
        _taskMetadataPointer = newTaskPointerHash;
    }
}