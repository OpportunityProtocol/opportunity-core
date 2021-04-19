// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./WorkExchange.sol";
import "../user/UserSummary.sol";
import "../libraries/Evaluation.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WorkRelationship is Ownable {
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

    address private _currentWorkExchange;

    constructor() {
        bool passesEvaluation = checkWorkerEvaluation(newWorker, evaluationState);
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
        selfdestruct();
    }
}