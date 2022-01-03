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

    address public worker;
    address public owner;
    address public market;
    uint public wad;

    DaiToken public daiToken;

    string public taskMetadataPointer;
    bytes32 private taskSolutionPointer;

    // keccak256("Work(bool _accepted)")
    bytes32 public constant WORK_TYPEHASH = 0xc35792dec8ea736e1a3478771b1f14a7472fd98ca01a9c9077ac63917f87f649;
    // keccak256("Review(bool _approve)")
    bytes32 public constant REVIEW_TYPEHASH = 0xfa5e0016fb62b8dffda8fd95249d438edcffd3689b40ac3b4281d4cf710609ae;
    // keccak256("Submit(bytes32 _submission)")
    bytes32 public constant SUBMIT_TYPEHASH = 0x62b607caa4d4e7fcbd31bf4c033cd30888b536567fadc83710fdf15f8d5cfc9e;
    bytes32 public immutable domain_separator;


    Relationship.ContractStatus public contractStatus;
    ContractState public contractState;
    ContractOwnership public contractOwnership;
    Evaluation.ContractType public contractType;

    uint256 acceptanceTimestamp;
    uint8 numSubmissions;

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

    enum ContractType {
        NORMAL,
        FLASH
    }

    modifier onlyContractParticipants() {
        require(msg.sender == worker || msg.sender == owner, "Only the contract participants may call this function.");
        _;
    }

    modifier onlyWorker() 
    {
        require(
            msg.sender == worker,
            "WorkRelationship: only"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() 
    {
        require(
            msg.sender == owner,
            "WorkRelationship: onlyOwner can call this function."
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
            daiToken = DaiToken(_daiTokenAddress);
            market = msg.sender;
            numSubmissions = 0;
            registrar = UserRegistration(_registrar);
    
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

            owner = tx.origin;
            contractType = _contractType;
            contractOwnership = ContractOwnership.UNCLAIMED;
            contractState = ContractState.Uninitialized;
            contractStatus = Relationship.ContractStatus.AwaitingWorker;
            taskMetadataPointer = _taskMetadataPointer;
    }

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
        bytes32 sDeny
        ) 
        external 
        onlyOwner
        onlyWhenState(ContractState.Uninitialized)
        onlyWhenStatus(Relationship.ContractStatus.AwaitingWorker)
    {
        require(_newWorker != address(0), "Worker address must not be 0 when assigning new worker.");
        //require(_newWorker != owner, "You cannot work your own contract."); //COMMENTED FOR DEBUGGING
        require(_wad != 0, "Dai amount cannot be equal to 0.");

        uint256 userBalance = daiToken.balanceOf(owner);
        if (userBalance < _wad) { revert(); }

        wad = _wad;

        initialize(nonce, expiry, eV, eR, eS, vDeny, rDeny, sDeny);

        worker = _newWorker;

        contractOwnership = ContractOwnership.PENDING;
        contractStatus = Relationship.ContractStatus.AwaitingWorkerApproval;

        acceptanceTimestamp = block.timestamp;
        assert(worker == _newWorker);
        assert(contractOwnership == ContractOwnership.PENDING);
    }



        function initialize(
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint8 vDeny,
        bytes32 rDeny,
        bytes32 sDeny
        ) 
        internal
    {
        console.log(nonce);
        console.log(v);
        //console.log(r);
        //console.log(s);
        console.log(vDeny);
        //console.log(rDeny);
       // console.log(sDeny);
        console.log(expiry);
        
        // Unlock buyer's Dai balance to transfer `wad` to this contract.
        daiToken.permit(owner, address(this), nonce, expiry, true, v, r, s);

        // Transfer Dai from `buyer` to this contract.
        daiToken.pull(owner, wad);

        // Relock Dai balance of `buyer`.
        daiToken.permit(owner, address(this), nonce + 1, expiry, false, vDeny, rDeny, sDeny);
        contractState = ContractState.Initialized;
    }

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
        if (_accepted == true) {
            UserSummary employerSummary = UserSummary(registrar.getTrueIdentification(owner));
            UserSummary workerSummary = UserSummary(registrar.getTrueIdentification(worker));

            //set contract to claimed
            contractOwnership = ContractOwnership.CLAIMED;
            contractStatus = Relationship.ContractStatus.AwaitingSubmission;
            
            employerSummary.increaseContractsEntered(User.UserInterface.Employer);
            workerSummary.increaseContractsEntered(User.UserInterface.Worker);
        } else {
            worker = address(0);
            refundReward();
            contractOwnership = ContractOwnership.UNCLAIMED;
            contractStatus = Relationship.ContractStatus.AwaitingWorker;
        }
    }

    function refundReward() internal returns(bool) {
        bool success = daiToken.transfer(owner, wad);
        assert(success == true);
    }

    function refundUnclaimedContract() external 
    onlyOwner
    onlyWhenOwnership(ContractOwnership.UNCLAIMED)
    {
        refundReward();
    }

    function releaseJob() external
    onlyWorker
    onlyWhenOwnership(ContractOwnership.CLAIMED) 
    onlyWhenStatus(Relationship.ContractStatus.AwaitingSubmission)
    {
        require(wad != uint(0), "There is no DAI to transfer back to the owner");
        refundReward();
    }

    function claimStalledContract() external 
    onlyOwner
    onlyWhenOwnership(ContractOwnership.CLAIMED) 
    {
        require(numSubmissions >= 1);
        require(acceptanceTimestamp >= (block.timestamp + 90 days));
        refundReward();
    }

    function submit(
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
        //require(worker == ecrecover(digest, _v, _r, _s), "invalid-permit");

        updateTaskSolutionPointer(_submission);
        contractStatus = Relationship.ContractStatus.AwaitingReview;
        numSubmissions++;
    }

    function review(
        uint256 averageMarketWorkerRep,
        uint8 _evaluationScore,
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

        //require(owner == ecrecover(digest, _v, _r, _s), "invalid-permit");

        if (_approve) {
            resolve();
        } else {
            contractStatus = Relationship.ContractStatus.AwaitingSubmission;
        }
    }

    function resolve() 
    internal
    onlyOwner
    {
        require(worker != address(0));
        contractStatus = Relationship.ContractStatus.Approved;
        contractState = ContractState.Locked;
        resolveReward();
    }


    function resolveReward() 
    internal
    {
        UserSummary employerSummary = UserSummary(registrar.getTrueIdentification(owner));
        UserSummary workerSummary = UserSummary(registrar.getTrueIdentification(owner));
        
        //alter the employers successful payouts
        employerSummary.increaseContractsCompleted(User.UserInterface.Employer);
        workerSummary.increaseContractsCompleted(User.UserInterface.Worker);

        bool success = daiToken.transfer(worker, wad);
        assert(success == true);
    }

    function updateTaskMetadataPointer(string memory newTaskPointerHash)
        external
        onlyOwner
        onlyWhenOwnership(ContractOwnership.UNCLAIMED)
    {
        taskMetadataPointer = newTaskPointerHash;
    }

    function updateTaskSolutionPointer(bytes32 newTaskPointerHash)
    internal
    {
        taskSolutionPointer = newTaskPointerHash;
    }

    function getTaskSolutionPointer()
        external
        view
        onlyOwner
        onlyWorker
        returns (bytes32)
    {
        return taskSolutionPointer;
    }

    function getRewardAddress() external returns(address) {
        require(address(daiToken) != address(0), "Reward address cannot be 0");
        return address(daiToken);
    }
}
