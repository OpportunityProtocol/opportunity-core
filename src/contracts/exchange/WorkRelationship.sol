// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../user/UserSummary.sol";
import "../libraries/Evaluation.sol";
import "../reputation/Tip.sol";
import "./WorkExchange.sol";

contract WorkRelationship {
    address public _workerAddress;
    address private _owner;

    string public _taskMetadataPointer = "";
    string private _taskSolutionPointer = "";

    WorkExchange _workExchange;
    Evaluation.WorkRelationshipState public _contractStatus;

    modifier onlyWorker() {
        require(
            worker() == msg.sender,
            "WorkRelationship: caller is not the worker"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(
            owner() == msg.sender,
            "WorkRelationship: caller is not the owner"
        );
        _;
    }

    constructor(address jobRequester, string memory taskMetadataPointer) { 
        require(jobRequester != address(0));
        _owner = jobRequester;
        _contractStatus = Evaluation.WorkRelationshipState.UNCLAIMED;
        _taskMetadataPointer = taskMetadataPointer;

        _workExchange.deposit(jobRequester);
    }

    function worker() public view returns (address) {
        return _workerAddress;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    function completeContract() external onlyOwner {
        require(_contractStatus != Evaluation.WorkRelationshipState.COMPLETED, "This relationship is already completed");
        
        _contractStatus = Evaluation.WorkRelationshipState.COMPLETED;
        _workExchange.beneficiaryWithdraw();

    }

    function updateRelationshipState(uint newState) external {
        
    }

    function assignNewWorker(address payable newWorker) external onlyOwner {
        require(newWorker != address(0));
        require(_contractStatus == Evaluation.WorkRelationshipState.UNCLAIMED);

        _workerAddress = newWorker;
        _workExchange = new WorkExchange(newWorker);
        _contractStatus = Evaluation.WorkRelationshipState.CLAIMED;

        assert(address(_workExchange) != address(0));
        assert(_workerAddress == newWorker);
        assert(_contractStatus == Evaluation.WorkRelationshipState.CLAIMED);
    }

    function unAssignWorker() external onlyOwner onlyWorker {
        require(_contractStatus != Evaluation.WorkRelationshipState.COMPLETED);
        require(_contractStatus != Evaluation.WorkRelationshipState.COMPLETED);

        _workerAddress = address(0);
        _contractStatus = Evaluation.WorkRelationshipState.UNCLAIMED;

        assert(worker() == address(0));
        assert(_contractStatus == Evaluation.WorkRelationshipState.UNCLAIMED);
    }

    function checkWorkerEvaluation(
        address workerUniversalAddress,
        Evaluation.EvaluationState memory evaluationState
    ) external returns (bool) {
        bool passesEvaluation = UserSummary(workerUniversalAddress)
        .evaluateUser(evaluationState);
        return passesEvaluation;
    }

    function updateTaskMetadataPointer(string memory newTaskPointerHash)
        external
        onlyOwner
    {
        _taskMetadataPointer = newTaskPointerHash;
    }

    function updateTaskSolutionPointer(string memory newTaskPointerHash)
        external
        onlyWorker
    {
        _taskSolutionPointer = newTaskPointerHash;
    }

    function getTaskSolutionPointer()
        external
        view
        onlyOwner
        returns (string memory)
    {
        return _taskSolutionPointer;
    }
}
