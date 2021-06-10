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
    string private _taskSolutionPointer = "";
    address public workerAddress;

    modifier onlyWorker() {
        require(msg.sender == workerAddress);
        _;
    }
    

    constructor(address marketAddress) {
        _contractStatus = Evaluation.WorkRelationshipState.UNCLAIMED;
        emit WorkRelationshipCreated(owner(), address(this), marketAddress);
    }

    function assignNewWorker(address newWorker, Evaluation.EvaluationState memory evaluationState) external onlyOwner {
        bool passesEvaluation = checkWorkerEvaluation(newWorker, evaluationState);
        require(passesEvaluation == true);

        _workExchangeAddress = newWorker;
    }

    function checkWorkerEvaluation(address workerUniversalAddress, Evaluation.EvaluationState memory evaluationState) internal returns(bool) {
        bool passesEvaluation = UserSummary(workerUniversalAddress).evaluateUser(evaluationState);
        return passesEvaluation;
    }

    function disableWorkRelationship() external onlyOwner {
        require(_contractStatus == Evaluation.WorkRelationshipState.COMPLETED);
        emit WorkRelationshipEnded(owner(), address(this));
    }

    function updateTaskMetadataPointer(string memory newTaskPointerHash) onlyOwner external {
        _taskMetadataPointer = newTaskPointerHash;
    }

    function updateTaskSolutionPointer(string memory newTaskPointerHash) onlyWorker external {
        _taskSolutionPointer = newTaskPointerHash;
    }

    function getTaskSolutionPointer() view external onlyOwner returns(string memory)  {
        return _taskSolutionPointer;
    }
}