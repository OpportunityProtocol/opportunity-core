// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../user/UserSummary.sol";
import "../libraries/Evaluation.sol";
import "./interface/IDaiToken.sol";
import "../dispute/Dispute.sol";
import "../libraries/Relationship.sol";
import "hardhat/console.sol";

// / @author Vypo Mouse (Forked and modified by Elijah Hampton) - https://forum.openzeppelin.com/t/feedback-on-dai-escrow-contract-that-reimburses-a-relayer-using-uniswap/2771
// / @title DaiEscrow
// / @notice Holds Dai tokens in escrow until the buyer and seller agree to
// /         release them.
// / @dev First construct the contract, specifying the buyer and seller addresses.
// /      Then `initialize` the contract with signatures for Dai's `permit`. This
// /      transfers Dai from the buyer to the escrow contract.
// /
// /      When the seller has completed their responsibilities, the seller
// /      calls `submit` on their behalf.
// /
// /      Once `submit` has been called, the buyer has ~30 days to call `review`.
// /      If the buyer does not call `review`, anyone may call `reviewPastDue` to
// /      release the funds to the seller.
// /
// /      When `review` is called, the buyer may choose to approve the submission
// /      or not approve it. If the submission is approved, the funds are released
// /      to the seller. If the buyer does not approve, the funds are locked
// /      forever.

interface CErc20 {
    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function balanceOfUnderlying(address owner) external returns (uint);
}

contract WorkRelationship {

    address public worker;
    address public owner;
    uint public wad;

    DaiToken daiToken;

    address public dispute;

    string public taskMetadataPointer;
    bytes32 private taskSolutionPointer;

    // keccak256("Work(bool _accepted)")
    bytes32 public constant WORK_TYPEHASH = 0xc35792dec8ea736e1a3478771b1f14a7472fd98ca01a9c9077ac63917f87f649;
    // keccak256("Review(bool _approve)")
    bytes32 public constant REVIEW_TYPEHASH = 0xfa5e0016fb62b8dffda8fd95249d438edcffd3689b40ac3b4281d4cf710609ae;
    // keccak256("Submit(bytes32 _submission)")
    bytes32 public constant SUBMIT_TYPEHASH = 0x62b607caa4d4e7fcbd31bf4c033cd30888b536567fadc83710fdf15f8d5cfc9e;
    bytes32 public immutable domain_separator;

    uint8 public constant LOW_MEDIAN_EVALUATION_THRESHOLD = 4;
    uint8 public constant HIGH_MEDIAN_EVALUATION_THRESHOLD = 6;

    Relationship.ContractStatus public contractStatus;
    ContractState public contractState;
    ContractOwnership public contractOwnership;
    Evaluation.ContractType public contractType;

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

    modifier onlyInDisputedConditions(address sender) {
        require(Relationship.ContractStatus.Disputed == contractStatus && sender == dispute, "The contract cannot be resolved under these conditions.");
        _;
    }

     constructor(
        address _owner, 
        Evaluation.ContractType _contractType, 
        string memory _taskMetadataPointer,
                address _daiTokenAddress
        ) { 
                    require(_daiTokenAddress != address(0), "Dai token address cannot be 0 when creating escrow.");

        daiToken = DaiToken(_daiTokenAddress);

        uint8 chain_id;
        assembly {
            chain_id := chainid()
        }


        domain_separator = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("Work Relationship")),
            keccak256(bytes("1")),
            chain_id,
            address(this)
        ));

        owner = _owner;

        contractType = _contractType;
        contractOwnership = ContractOwnership.UNCLAIMED;
        contractState = ContractState.Uninitialized;
        contractStatus = Relationship.ContractStatus.AwaitingWorker;

        taskMetadataPointer = _taskMetadataPointer;
    }

    function assignNewWorker(
        address payable _newWorker, 
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
        require(_wad != 0, "Dai amount cannot be equal to 0.");

        uint256 userBalance = daiToken.balanceOf(owner);
        if (userBalance < _wad) { revert(); }

        initialize(nonce, expiry, eV, eR, eS, vDeny, rDeny, sDeny);

        wad = _wad;
        worker = _newWorker;
        dispute = address(0);

        contractOwnership = ContractOwnership.PENDING;
        contractStatus = Relationship.ContractStatus.AwaitingWorkerApproval;

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
            //set contract to claimed
            contractOwnership = ContractOwnership.CLAIMED;
            contractStatus = Relationship.ContractStatus.AwaitingSubmission;
        } else {
            worker = address(0);
            refundReward();
            contractOwnership = ContractOwnership.UNCLAIMED;
            contractStatus = Relationship.ContractStatus.AwaitingWorker;
        }
    }

    function refundReward() 
    internal
    onlyWorker
    onlyWhenOwnership(ContractOwnership.PENDING) 
    onlyWhenStatus(Relationship.ContractStatus.AwaitingWorkerApproval)
    {
        require(wad != uint(0), "There is no DAI to transfer back to the owner");

        //Escrow sends money back to owner
        daiToken.transfer(owner, wad);
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
            resolve(_evaluationScore, averageMarketWorkerRep);
        } else {
            contractStatus = Relationship.ContractStatus.AwaitingSubmission;
        }
    }

    function resolveTiedDisputedReward() 
    external 
    onlyInDisputedConditions(msg.sender) {
        uint fairSplit = wad / 2;
        
        daiToken.transfer(owner, fairSplit);
        daiToken.transfer(worker, fairSplit);
    }

    function resolveDisputedReward(address _beneficiary) 
    external
    onlyInDisputedConditions(msg.sender)
     {
        daiToken.transfer(_beneficiary, wad);

        //alter the workers reputation

        //alter the employers disputes
    }

    function resolveReward(uint8 _evaluationScore, uint256 _averageMarketWorkerRep) 
    internal
     {
        daiToken.transfer(worker, wad);

        UserSummary employerSummary = UserSummary(owner);
        UserSummary workerSummary = UserSummary(worker);

        //get worker reputation for the market this relationship is in
        uint8 workerReputation = 0;

        //alter the workers reputation according to the evaluation score
        if (_evaluationScore > HIGH_MEDIAN_EVALUATION_THRESHOLD) {
            workerSummary.increaseReputation(address(this), 1);
        } else if (_evaluationScore <= HIGH_MEDIAN_EVALUATION_THRESHOLD 
            || _evaluationScore >= LOW_MEDIAN_EVALUATION_THRESHOLD) {
            //nothing
        } else if (_evaluationScore <= LOW_MEDIAN_EVALUATION_THRESHOLD 
            && workerReputation >= _averageMarketWorkerRep + 1) {
            uint8 badConsistencyCount = workerSummary.getBadConsistencyCount();
            if (badConsistencyCount <= 1) {
                //decrease worker reputation by one
                workerSummary.decreaseReputation(address(this), 1);
            } else if (badConsistencyCount == 2) {
                //decrease worker reputation by half the average reputation
                uint8 decreaseAmount = 0;
                workerSummary.decreaseReputation(address(this), decreaseAmount);
            } else if (badConsistencyCount == 3) {
                //decrease worker reputation count to 0
                workerSummary.decreaseReputation(address(this), 0);
                //reset consistency count
                workerSummary.setBadConsistencyCount(0);
            } else { //if it is above 4 there is some error and we should reset it, increase it and then handle the reputation
                //set consistency count 1
                workerSummary.setBadConsistencyCount(1);
                //decrease reputation by 1
                workerSummary.decreaseReputation(address(this), 1);
            }
        } else if (_evaluationScore <= LOW_MEDIAN_EVALUATION_THRESHOLD && workerReputation < _averageMarketWorkerRep) {
            //decrease worker reputation by 1
            workerSummary.decreaseReputation(address(this), 1);
        }

        //alter the employers successful payouts
        employerSummary.increaseSuccessfulPayout(address(this));
    }

      function resolve(uint8 _evaluationScore, uint256 _averageMarketWorkerRep) 
        internal
        onlyOwner
    {
        require(worker != address(0));

        resolveReward(_evaluationScore, _averageMarketWorkerRep);
        
        contractStatus = Relationship.ContractStatus.Approved;
        contractState = ContractState.Locked;
    }

    function checkWorkerEvaluation(
        address workerUniversalAddress,
        Evaluation.EvaluationState memory evaluationState,
        address _market
        ) 
        external returns (bool) 
    {
        bool passesEvaluation = UserSummary(workerUniversalAddress)
        .evaluateUser(evaluationState, _market);
        return passesEvaluation;
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

    function disputeRelationship(
        address _scheduler,         
        bytes32 _complaintMetadataPointer,
        bytes32 _complaintResponseMetadataPointer,
        address userRegistrationAddress
        ) 
        external 
        onlyOwner
        onlyWorker
        onlyWhenStatus(Relationship.ContractStatus.AwaitingSubmission) 
    {
        dispute = address(new Dispute(address(this), _complaintMetadataPointer, _complaintResponseMetadataPointer));

        assert(dispute != address(0));

        contractStatus = Relationship.ContractStatus.Disputed;

        UserRegistration registration = UserRegistration(userRegistrationAddress);
        address userSummary = registration._trueIdentifcations[msg.sender];

        userSummary.disputedContractParticipation(dispute);
    }

    function getRewardAddress() external returns(address) {
        require(address(daiToken) != address(0), "Reward address cannot be 0");
        return address(daiToken);
    }
}
