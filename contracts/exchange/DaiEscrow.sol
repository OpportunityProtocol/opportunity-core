//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "../user/UserSummary.sol";

/// Dai Token Interface
interface DaiToken {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) 
    external;

    function pull(address usr, uint wad) external;
    function push(address usr, uint wad) external;
    function approve(address usr, uint wad) external returns (bool);
    function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IBanker {
    function supplyErc20ToCompound(
        address _erc20Contract,
        address _cErc20Contract,
        address _donor,
        uint256 _numTokensToSupply
    ) external returns (uint);
}

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
contract DaiEscrow {
  enum Status {
        AwaitingWorker,
        AwaitingWorkerApproval,
        AwaitingSubmission,
        AwaitingReview,
        Approved
    }

  enum ContractState {
      Initialized,
      Uninitialized,
      Locked
  }

    // keccak256("Review(bool _approve)")
    bytes32 public constant REVIEW_TYPEHASH = 0xfa5e0016fb62b8dffda8fd95249d438edcffd3689b40ac3b4281d4cf710609ae;
    // keccak256("Submit(bytes32 _submission)")
    bytes32 public constant SUBMIT_TYPEHASH = 0x62b607caa4d4e7fcbd31bf4c033cd30888b536567fadc83710fdf15f8d5cfc9e;
    bytes32 public immutable domain_separator;

    address public beneficiary;
    address public depositor;

    uint public wad;

    DaiToken daiToken;
    address cDaiToken;
    IBanker banker;

    bytes32 private _taskSolutionPointer = "";

    Status public status;
    ContractState public state;
    
    modifier onlyOwner() {
        require(depositor == msg.sender, "Owner can only resolve contract.");
        _;
    }

    modifier onlyBeneficiary() {
        require(depositor == beneficiary, "Worker can only call this function");
        _;
    }

    modifier onlyWhen(Status _status) 
    {
        require(status == _status, "Cannot invoke this escrow function with the current contract status.");
        _;
    }

    modifier onlyWhenState(ContractState _state) 
    {
        require(state == _state, "Cannot invoke this escrow function with the current contract state.");
        _;
    }

    constructor (
        address _depositor,
        address _beneficiary,
        uint _wad,
        address _daiTokenAddress,
        address _cDaiTokenAddress,
        address _banker,
        uint256 nonce,
        uint256 expiry,
        uint8 eV,
        bytes32 eR,
        bytes32 eS
    ) 
    {
        require(_depositor != address(0), "Depositor address cannot be 0 when creating escrow.");
        require(_beneficiary != address(0), "Beneficiary address cannot be 0 when creating escrow.");
        require(_daiTokenAddress != address(0), "Dai token address cannot be 0 when creating escrow.");
        require(_cDaiTokenAddress != address(0), "cDai token address cannot be 0 when creating escrow.");
        require(_banker != address(0), "Banker address cannot be 0 when creating escrow.");
        require(_wad != 0, "Dai amount cannot be equal to 0.");
        
        daiToken = DaiToken(_daiTokenAddress);
        cDaiToken = _cDaiTokenAddress;

        uint256 userBalance = daiToken.balanceOf(_depositor);
        if (userBalance < _wad) { revert(); }

        uint8 chain_id;

        assembly {
            chain_id := chainid()
        }

        domain_separator = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("Dai Escrow")),
            keccak256(bytes("1")),
            chain_id,
            address(this)
        ));

        wad = _wad;
        depositor = _depositor;
        beneficiary = beneficiary;
        state = ContractState.Uninitialized;

        initialize(nonce, expiry, eV, eR, eS);
        assignNewBeneficiary(_beneficiary);
    }

    function initialize(
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
        ) 
        internal
    {
        // Unlock buyer's Dai balance to transfer `wad` to this contract.
        daiToken.permit(depositor, address(this), nonce, expiry, true, v, r, s);

        // Transfer Dai from `buyer` to this contract.
        daiToken.pull(depositor, wad);

        // Relock Dai balance of `buyer`.
        daiToken.permit(depositor, address(this), nonce + 1, expiry, false, v, r, s);

        state = ContractState.Initialized;
        status = Status.AwaitingWorker;
    }

    function refundReward() 
    external 
    onlyBeneficiary
    onlyWhenState(ContractState.Initialized) 
    onlyWhen(Status.AwaitingWorkerApproval)
    {
        require(wad != uint(0), "There is no DAI to transfer back to the depositor");

        //Escrow sends money back to depositor
        daiToken.transfer(depositor, wad);

        //lock contract
        state = ContractState.Locked;
    }

    function assignNewBeneficiary(
        address _beneficiary
        ) 
        internal 
        onlyWhen(Status.AwaitingWorker)
    {
        require(beneficiary != address(0), "assignNewBeneficiary(): beneficiary address cannot be 0");
        beneficiary = _beneficiary;

        status = Status.AwaitingWorkerApproval;
    }

    function stakeReputation(uint stake, uint8 wV, bytes32 wR, bytes32 wS) onlyWhen(Status.AwaitingWorkerApproval) external {
        //stake the workers reputation by the required amount
        //TODO: Do rep calculation
        uint requiredReputation = 0;
        require(stake == requiredReputation, "Worker does not have the rep necessary to accept this job.");

        //TODO: sign and do erecover

         //UserSummary userSummary = UserSummary(_beneficiary);
        //TODO: userSummary.stakeReputation(beneficiary, stake);
        status = Status.AwaitingSubmission;
            
    }

    function submit(
        bytes32 _submission,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
        ) 
        external 
        onlyBeneficiary
        onlyWhen(Status.AwaitingSubmission) 
    {
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            domain_separator,
            keccak256(abi.encode(SUBMIT_TYPEHASH, _submission))
        ));

        require(beneficiary != address(0));
        //require(beneficiary == ecrecover(digest, _v, _r, _s), "invalid-permit");

        updateTaskSolutionPointer(_submission);

        status = Status.AwaitingReview;
    }

    function resolve() 
        internal
        onlyOwner
    {
        require(beneficiary != address(0));

        //daiToken.push(beneficiary, daiToken.balanceOf(address(this)));
        banker.supplyErc20ToCompound(address(daiToken), address(cDaiToken), depositor, daiToken.balanceOf(address(this)));
        status = Status.Approved;
        state = ContractState.Locked;
    }

       function review(
        bool _approve,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
        ) 
        external 
        onlyOwner
        onlyWhen(Status.AwaitingReview) 
    {
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            domain_separator,
            keccak256(abi.encode(REVIEW_TYPEHASH, _approve))
        ));

        //require(depositor == ecrecover(digest, _v, _r, _s), "invalid-permit");

        if (_approve) {
            resolve();
        } else {
            status = Status.AwaitingSubmission;
        }
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
        onlyBeneficiary
        returns (bytes32)
    {
        return _taskSolutionPointer;
    }
}