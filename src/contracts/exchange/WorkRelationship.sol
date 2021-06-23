// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../user/UserSummary.sol";
import "../libraries/Evaluation.sol";

contract WorkRelationship {

    address public _workExchangeAddress;
    address public _workerAddress;
    address private _owner;

    string public _taskMetadataPointer = "";
    string private _taskSolutionPointer = "";

    Evaluation.WorkRelationshipState public _contractStatus;

    modifier onlyWorker() {
        require(
            msg.sender == _workerAddress,
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

    constructor(address jobRequester, string memory taskMetadataPointer) public payable {
        require(jobRequester != address(0));
        _owner = jobRequester;
        _contractStatus = Evaluation.WorkRelationshipState.UNCLAIMED;
        _taskMetadataPointer = taskMetadataPointer;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    function assignNewWorker(
        address newWorker,
        Evaluation.EvaluationState memory evaluationState
    ) external onlyOwner {
        bool passesEvaluation =
            checkWorkerEvaluation(newWorker, evaluationState);
        require(passesEvaluation == true);

        _workerAddress = newWorker;
    }

    function checkWorkerEvaluation(
        address workerUniversalAddress,
        Evaluation.EvaluationState memory evaluationState
    ) internal returns (bool) {
        bool passesEvaluation =
            UserSummary(workerUniversalAddress).evaluateUser(evaluationState);
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

    withdraw
}
