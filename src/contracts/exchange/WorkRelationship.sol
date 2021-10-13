// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../user/UserSummary.sol";
import "./WorkExchange.sol";
import "../libraries/Evaluation.sol";

contract WorkRelationship {

    address public worker;
    address public owner;
    address public immutable workExchange;

    string public _taskMetadataPointer = "";
    bytes32 private _taskSolutionPointer = "";

    uint public contractPayout;

    Evaluation.WorkRelationshipState public _contractStatus;
    Evaluation.ContractType public contractType;

    modifier onlyWorker() 
    {
        require(
            worker == msg.sender,
            "WorkRelationship: caller is not the worker"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() 
    {
        require(
            owner == msg.sender,
            "WorkRelationship: caller is not the owner"
        );
        _;
    }

    modifier onlyWhenState(Evaluation.WorkRelationshipState status) 
    {
        require(_contractStatus == status, "This action cannot be carried out under the current contract status.");
        _;
    }

    modifier onlyWhenType(Evaluation.ContractType currentContractType) 
    {
        require(contractType == currentContractType, "This action cannot be carried out under this contract type");
        _;
    }

     constructor(
        address _owner, 
        Evaluation.ContractType _contractType, 
        string memory taskMetadataPointer, 
        uint256 _wad,
        address _daiTokenAddress
        ) payable { 
        require(_wad != 0, "Must send more than 0 dai to this contract.");
        owner = _owner;
        worker = address(0);
        contractType = _contractType;
        contractPayout = _wad;
        _contractStatus = Evaluation.WorkRelationshipState.UNCLAIMED;
        _taskMetadataPointer = taskMetadataPointer;

        WorkExchange workExchangeContract = new WorkExchange(
            owner, 
            _wad, 
            _daiTokenAddress);
        
        workExchange = address(workExchangeContract);
    }

    function assignNewWorker(
        address payable _newWorker, 
        uint256 _stakedReputation
        ) 
        external 
        onlyOwner
    {
        require(_newWorker != address(0), "Worker address must not be 0 when assigning new worker.");

        worker = _newWorker;
        WorkExchange(workExchange).assignNewBeneficiary(_newWorker, _stakedReputation);
        _contractStatus = Evaluation.WorkRelationshipState.CLAIMED;

        assert(workExchange != address(0));
        assert(worker == _newWorker);
        assert(_contractStatus == Evaluation.WorkRelationshipState.CLAIMED);
    }

    function unAssignWorker() external onlyWorker onlyWhenState(Evaluation.WorkRelationshipState.CLAIMED)
    {
        worker = address(0);
        _contractStatus = Evaluation.WorkRelationshipState.UNCLAIMED;

        assert(worker == address(0));
        assert(_contractStatus == Evaluation.WorkRelationshipState.UNCLAIMED);
    }

    function checkWorkerEvaluation(
        address workerUniversalAddress,
        Evaluation.EvaluationState memory evaluationState
        ) 
        external returns (bool) 
    {
        bool passesEvaluation = UserSummary(workerUniversalAddress)
        .evaluateUser(evaluationState);
        return passesEvaluation;
    }

    function updateTaskMetadataPointer(string memory newTaskPointerHash)
        external
        onlyOwner
        onlyWhenState(Evaluation.WorkRelationshipState.UNCLAIMED)
    {
        _taskMetadataPointer = newTaskPointerHash;
    }

    function updateTaskSolutionPointer(bytes32 newTaskPointerHash)
        internal
    {
        _taskSolutionPointer = newTaskPointerHash;
    }

    function getTaskSolutionPointer()
        external
        view
        onlyOwner
        onlyWorker
        returns (bytes32)
    {
        return _taskSolutionPointer;
    }
    
    function submitDispute(address disputor) 
        external 
        onlyWorker 
        onlyOwner 
    {
        WorkExchange(workExchange).disputeFunds(disputor);
    }

    function submitWork(
        bytes32 _submission,
        uint8 _v,
        bytes32 _r,
        bytes32 _s) 
        onlyWorker 
        onlyWhenState(Evaluation.WorkRelationshipState.CLAIMED)
        external 
    {
        WorkExchange(workExchange).submit(_submission, _v, _r, _s);
        updateTaskSolutionPointer(_submission);
    }

    function submitWorkEvaluation(
        bool _approved,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
        ) 
        onlyOwner 
        external 
    {
        WorkExchange(workExchange).review(_approved, _v, _r, _s);
    }
}
