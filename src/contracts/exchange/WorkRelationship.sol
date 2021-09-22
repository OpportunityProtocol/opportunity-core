// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../user/UserSummary.sol";
import "../libraries/Evaluation.sol";
import "./WorkExchange.sol";

contract WorkRelationship {
    address public worker;
    address public owner;

    string public _taskMetadataPointer = "";
    string private _taskSolutionPointer = "";

    address public immutable workExchange;
    Evaluation.WorkRelationshipState public _contractStatus;

    Evaluation.ContractType public contractType;

    uint public contractPayout;

    modifier onlyWorker() {
        require(
            worker == msg.sender,
            "WorkRelationship: caller is not the worker"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(
            owner == msg.sender,
            "WorkRelationship: caller is not the owner"
        );
        _;
    }

    modifier onlyOwnerWhenNotFlash() {
        if (contractType == Evaluation.ContractType.FLASH) {
            _;
        } else {
            require(owner == msg.sender, "Caller is not owner and contract is not flash.");
        }
        _;
    }

    modifier onlyWhen(Evaluation.WorkRelationshipState status) {
        require(_contractStatus == status);
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
        _contractStatus = Evaluation.WorkRelationshipState.UNCLAIMED;
        _taskMetadataPointer = taskMetadataPointer;

        WorkExchange workExchangeContract = new WorkExchange(
            owner, 
            _wad, 
            _daiTokenAddress);
        
        workExchange = address(workExchangeContract);
    }

    function updateContractPayout(uint amount) external onlyOwner {
        //send back vaalue
    }

    function completeContract() external onlyOwner {
        require(_contractStatus != Evaluation.WorkRelationshipState.COMPLETED, "This relationship is already completed");
        
        _contractStatus = Evaluation.WorkRelationshipState.COMPLETED;
        //workExchange.beneficiaryWithdraw();

    }

    function updateRelationshipState(uint newState) external {
        
    }

    function assignNewWorker(
        address payable _newWorker, 
        uint256 _stakedReputation
        ) external onlyOwnerWhenNotFlash {
        require(_newWorker != address(0));

        worker = _newWorker;

        WorkExchange(workExchange).assignNewBeneficiary(_newWorker, _stakedReputation);
            
        _contractStatus = Evaluation.WorkRelationshipState.CLAIMED;

        assert(workExchange != address(0));
        assert(worker == _newWorker);
        assert(_contractStatus == Evaluation.WorkRelationshipState.CLAIMED);
    }

    function unAssignWorker() external onlyWorker {
        require(_contractStatus != Evaluation.WorkRelationshipState.COMPLETED);
        require(_contractStatus != Evaluation.WorkRelationshipState.COMPLETED);

        worker = address(0);
        _contractStatus = Evaluation.WorkRelationshipState.UNCLAIMED;

        assert(worker == address(0));
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
        onlyWorker onlyWhen(Evaluation.WorkRelationshipState.CLAIMED)
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
    
    function submitDispute(address disputor) external{
        WorkExchange(workExchange).disputeFunds(disputor);
    }

    function submitWork(
        bytes32 _submission,
        uint8 _v,
        bytes32 _r,
        bytes32 _s) onlyWorker external {
        WorkExchange(workExchange).submit(_submission, _v, _r, _s);
    }

    function submitWorkEvaluation(
        bool _approved,
        uint8 _v,
        bytes32 _r,
        bytes32 _s) onlyOwner external {
        WorkExchange(workExchange).review(_approved, _v, _r, _s);
    }
}
