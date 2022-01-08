// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../user/UserSummary.sol";
import "../libraries/User.sol";
import "../libraries/Evaluation.sol";
import "./interface/IDaiToken.sol";
import "../libraries/Relationship.sol";
import "../user/UserRegistration.sol";
import "hardhat/console.sol";

contract WorkRelationship {

    event EnteredContract(address indexed owner, address indexed worker, address indexed relationship);
    event ContractCompleted(address indexed owner, address indexed worker, address indexed relationship);
    event ContractStatusUpdated(address indexed relationship, uint8 indexed status);

    address public worker;
    address public owner;
    address public market;
    uint public wad;
    string public taskMetadataPointer;
    uint256 acceptanceTimestamp;
    //bytes32 private taskSolutionPointer;
    //uint8 numSubmissions;

    DaiToken public daiToken;


    bytes32 public immutable domain_separator;
    
    // keccak256("Work(bool _accepted)")
    bytes32 public constant WORK_TYPEHASH = 0xc35792dec8ea736e1a3478771b1f14a7472fd98ca01a9c9077ac63917f87f649;
    // keccak256("Review(bool _approve)")
    bytes32 public constant REVIEW_TYPEHASH = 0xfa5e0016fb62b8dffda8fd95249d438edcffd3689b40ac3b4281d4cf710609ae;
    // keccak256("Submit(bytes32 _submission)")
    bytes32 public constant SUBMIT_TYPEHASH = 0x62b607caa4d4e7fcbd31bf4c033cd30888b536567fadc83710fdf15f8d5cfc9e;


    Relationship.ContractStatus public contractStatus;
    ContractState public contractState;
    ContractOwnership public contractOwnership;
    Evaluation.ContractType public contractType;

    UserRegistration registrar;

    enum ContractState {
        Uninitialized,
        Initialized,
        Locked
    }

    enum ContractOwnership { 
        UNCLAIMED,
        PENDING,
        CLAIMED
    }

    modifier onlyContractParticipants() {
        require(msg.sender == worker || msg.sender == owner, 
            "Only the contract participants may call this function.");
        _;
    }

    modifier onlyWorker() 
    {
        require(
            msg.sender == worker,
            "Only the worker of this contract may call this function."
        );
        _;
    }

    modifier onlyOwner() 
    {
        require(
            msg.sender == owner,
            "Only the owner of this contract may call this function."
        );
        _;
    }

    modifier onlyWhenStatus(Relationship.ContractStatus _statusOptionOne) 
    {
        require(contractStatus == _statusOptionOne, "This action cannot be carried out under the current contract status.");
        _;
    }

    modifier onlyWhenEitherStatus(Relationship.ContractStatus _statusOptionOne, Relationship.ContractStatus _statusOptionTwo) 
    {
        require(contractStatus == _statusOptionOne || contractStatus == _statusOptionTwo, "This action cannot be carried out under the current contract status.");
        _;
    }

    modifier onlyWhenType(Evaluation.ContractType currentContractType) 
    {
        require(contractType == currentContractType, "This action cannot be carried out under this contract type");
        _;
    }

    modifier onlyWhenOwnership(ContractOwnership _ownership) 
    {
        require(contractOwnership == _ownership, "Cannot invoke this escrow function with the current contract status.");
        _;
    }

    modifier onlyWhenState(ContractState _state) 
    {
        require(contractState == _state, "Cannot invoke this escrow function with the current contract state.");
        _;
    }

     constructor(
            address _registrar,
            Evaluation.ContractType _contractType, 
            string memory _taskMetadataPointer,
            address _daiTokenAddress
        ) { 
            require(_daiTokenAddress != address(0), "Dai token address cannot be 0 when creating escrow.");
            require(_registrar != address(0), "The address of the registrar for this contract cannot be set to 0.");
            daiToken = DaiToken(_daiTokenAddress);
            registrar = UserRegistration(_registrar);
            market = msg.sender;
            owner = tx.origin;
            //numSubmissions = 0;
            contractOwnership = ContractOwnership.UNCLAIMED;
            contractState = ContractState.Uninitialized;
            contractStatus = Relationship.ContractStatus.AwaitingWorker;
            taskMetadataPointer = _taskMetadataPointer;
    
            uint8 chain_id;
            assembly {
                chain_id := chainid()
            }

            console.log('Chain id: %s', chain_id);

            domain_separator = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("Work Relationship")),
            keccak256(bytes("1")),
            chain_id,
            address(this)
            ));

            emit ContractStatusUpdated(address(this), uint8(contractStatus));
    }

    /**
     * assignNewWorker
     * Assigns a new worker to this contract.  Called by the owner and moves DAI from the owners account into the
     * smart contract's account.
     * @param _newWorker The worker designated to work the contract
     * @param _wad The amount of DAI requested by the worker
     * @param nonce The current nonce of the contract caller
     * @param expiry The expiry of the dai PERMIT call
     * @param eV  //
     * @param eR //
     * @param eS //
     * @param vDeny //
     * @param rDeny //
     * @param sDeny //
     */
    function assignNewWorker(
    address _newWorker, 
    uint _wad,
    uint256 nonce,
    uint256 expiry,
    uint8 eV,
    bytes32 eR,
    bytes32 eS,
    uint8 vDeny,
    bytes32 rDeny,
    bytes32 sDeny) 
    external 
    onlyOwner
    onlyWhenState(ContractState.Uninitialized)
    onlyWhenStatus(Relationship.ContractStatus.AwaitingWorker)
    {
        require(_newWorker != address(0), "Worker address must not be 0 when assigning new worker.");
        //require(_newWorker != owner, "You cannot work your own contract."); //COMMENTED FOR DEBUGGING
        require(_wad != 0, "The payout amount for this contract cannot be 0.");
        require(daiToken.balanceOf(owner) >= _wad, "You do not have enough DAI to pay the specified amount.");
        
        wad = _wad;
        initialize(nonce, expiry, eV, eR, eS, vDeny, rDeny, sDeny);

        worker = _newWorker;
        
        contractOwnership = ContractOwnership.PENDING;
        contractStatus = Relationship.ContractStatus.AwaitingWorkerApproval;
        acceptanceTimestamp = block.timestamp;

        emit ContractStatusUpdated(address(this), uint8(contractStatus));
    }

    /**
     * initialize
     * Initializes the contract by pulling the dai from the employers account
     * @param nonce //
     * @param expiry //
     * @param v //
     * @param r //
     * @param s  //
     * @param vDeny //
     * @param rDeny //
     * @param sDeny  //
     */
    function initialize(
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s,
    uint8 vDeny,
    bytes32 rDeny,
    bytes32 sDeny) 
    internal
    {  
        // Unlock buyer's Dai balance to transfer `wad` to this contract.
        daiToken.permit(owner, address(this), nonce, expiry, true, v, r, s);

        // Transfer Dai from `buyer` to this contract.
        daiToken.pull(owner, wad)

        // Relock Dai balance of `buyer`.
        daiToken.permit(owner, address(this), nonce + 1, expiry, false, vDeny, rDeny, sDeny);
        contractState = ContractState.Initialized;
    }

    /**
     * work
     * The official "acceptance" of the contract by the worker. Workers call this function 
     * to officially accept or decline the contract
     * @param _accepted True or false based on the workers decision
     * @param wV //
     * @param wR //
     * @param wS //
     */
    function work(
    bool _accepted, 
    uint8 wV, 
    bytes32 wR, 
    bytes32 wS) 
    onlyWorker 
    onlyWhenState(ContractState.Initialized)
    onlyWhenStatus(Relationship.ContractStatus.AwaitingWorkerApproval)
    onlyWhenOwnership(ContractOwnership.PENDING) 
    external {
        require(msg.sender == worker, "Only the address designated to be the worker may call this function.");

        if (_accepted == true) {
            //set contract to claimed
            contractOwnership = ContractOwnership.CLAIMED;
            contractStatus = Relationship.ContractStatus.AwaitingReview;
            
            emit EnteredContract(owner, worker, address(this));
        } else {
            worker = address(0);
            refundReward();
            contractOwnership = ContractOwnership.UNCLAIMED;
            contractStatus = Relationship.ContractStatus.AwaitingWorker;
        }

        emit ContractStatusUpdated(address(this), uint8(contractStatus));
    }

    /**
     * refundReward
     * Transfers the payout back to the employer
     */
    function refundReward() 
    internal 
    returns(bool) {

        require(wad != uint(0), "There is no DAI to transfer back to the owner");
        bool success = daiToken.transfer(owner, wad);
        assert(success == true);
    }

    /**
     * refundUnclaimedContract
     * Returns the payout to the employer as long as no one has claimed the contract
     * and been made the worker
     */
    function refundUnclaimedContract() external 
    onlyOwner
    onlyWhenOwnership(ContractOwnership.UNCLAIMED)
    {
        refundReward();
    }

    /**
     * releaseJob
     * Returns the payout to the employer and releases the job.  Worker must have officially been 
     * made the worker by calling work() to call this function.
     * 
     */
    function releaseJob() external
    onlyWorker
    onlyWhenOwnership(ContractOwnership.CLAIMED) 
    {
        worker = address(0);
        //taskSolutionPointer = "";
        acceptanceTimestamp = 0;
        //numSubmissions = 0;

        contractState = ContractState.Uninitialized;
        contractOwnership = ContractOwnership.UNCLAIMED;
        contractStatus = Relationship.ContractStatus.AwaitingWorker;
        emit ContractStatusUpdated(address(this), uint8(contractStatus));
        refundReward();
    }

    /**
     * claimStalledContract
     * Allows the employer to reclaim the payout if 60 days 
     * have passed and no submissions have been made.
     */
    function claimStalledContract() external 
    onlyOwner
    onlyWhenOwnership(ContractOwnership.CLAIMED) 
    {
        //require(numSubmissions >= 1);
        require(acceptanceTimestamp >= (block.timestamp + 60 days));
        refundReward();
    }

    /**
     * resolve()
     * Resolves the contract and transfers the payout to the worker.
     */
    function resolve() 
    onlyOwner
    onlyWhenStatus(Relationship.ContractStatus.AwaitingReview)
    external
    {
        require(worker != address(0));
        require(owner != address(0));

        bool success = daiToken.transfer(worker, wad);
        assert(success == true);

        contractStatus = Relationship.ContractStatus.Approved;
        contractState = ContractState.Locked;

        emit ContractCompleted(owner, worker, address(this));
        emit ContractStatusUpdated(address(this), uint8(contractStatus));
    }

    /**
     * Allows the employer to update the task metadata as long as this contract is in the
     * unclaimed state
     */
    function updateTaskMetadataPointer(string memory newTaskPointerHash)
    external
    onlyOwner
    onlyWhenOwnership(ContractOwnership.UNCLAIMED)
    {
        taskMetadataPointer = newTaskPointerHash;
    }

    /**
     * submit()
     * Allows a worker to submit the work or proof of work.
     * @param _submission The hash on ipfs to the work or proof of work.
     * @param _v //
     * @param _r //
     * @param _s //
     */
    /*function submit(
        bytes32 _submission,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
        ) 
        external 
        onlyWorker
        onlyWhenStatus(Relationship.ContractStatus.AwaitingSubmission) 
    {
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            domain_separator,
            keccak256(abi.encode(SUBMIT_TYPEHASH, _submission))
        ));

        require(worker != address(0));
        //require(worker == ecrecover(digest, _v, _r, _s), "Invalid signature to submit()");

        updateTaskSolutionPointer(_submission);
        contractStatus = Relationship.ContractStatus.AwaitingReview;
        numSubmissions++;
    }*/

    /**
     * review()
     * Approves or rejects the current work or proof of work by the employer.
     * @param _approve //
     * @param _v //
     * @param _r //
     * @param _s //
     */
    /*function review(
        bool _approve,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
        ) 
        external 
        onlyOwner
        onlyWhenStatus(Relationship.ContractStatus.AwaitingReview)
    {
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            domain_separator,
            keccak256(abi.encode(REVIEW_TYPEHASH, _approve))
        ));

        //require(owner == ecrecover(digest, _v, _r, _s), "Only the employer of this contract can invoke this function.");

        if (_approve) {
            resolve();
        } else {
            contractStatus = Relationship.ContractStatus.AwaitingSubmission;
        }
    }*/

    /**
     * Updates the solution pointer upon the submit() 
     * function being called
     */
    /*function updateTaskSolutionPointer(bytes32 newTaskPointerHash)
    internal
    {
        taskSolutionPointer = newTaskPointerHash;
    }*/

    /**
     * Returns the solution pointer to the owner or worker of the contract
     * @return Returns the hash pointer
     */
    /*function getTaskSolutionPointer()
        external
        view
        onlyContractParticipants
        returns (bytes32)
    {
        return taskSolutionPointer;
    }*/
}
