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
    address immutable public depositor;

    uint immutable public wad;

    mapping(address => uint256) public storedFunds;

    Status public status;
    ContractState public state;

    DaiToken daiToken;

    modifier onlyWhen(Status _status) 
    {
        require(status == _status, "Cannot invoke this escrow function with the current contract status.");
        _;
    }

    constructor (
        address _depositor,
        uint _wad,
        address _daiTokenAddress
    ) 
    {
        require(_depositor != address(0), "Depositor address cannot be 0 when creating escrow.");
        require(_daiTokenAddress != address(0), "Dai token address cannot be 0 when creating escrow.");
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

        depositor = _depositor;
        wad = _wad;
        daiToken = DaiToken(_daiTokenAddress);
        state = ContractState.Uninitialized;
    }

    function initialize(
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
        ) 
        external 
    {
        // Unlock buyer's Dai balance to transfer `wad` to this contract.
        daiToken.permit(depositor, address(this), nonce, expiry, true, v, r, s);

        // Transfer Dai from `buyer` to this contract.
        daiToken.pull(depositor, wad);

        // Relock Dai balance of `buyer`.
        daiToken.permit(depositor, address(this), nonce + 1, expiry, false, v, r, s);

        status = Status.AwaitingWorker;
        state = ContractState.Initialized;
    }

    function assignNewBeneficiary(
        address payable _beneficiary, 
        uint256 _stakedReputation
        ) 
        external 
        onlyWhen(Status.AwaitingWorker)
    {
        require(_beneficiary != address(0), "Beneficiary cannot be 0x address when assigning new beneficiary");

        beneficiary = _beneficiary;
        
        //stake the workers reputation by the required amount
        //TODO: Need to revert if the user cannot fulfill the reputation requirements
        //UserSummary userSummary = UserSummary(_beneficiary);
        //userSummary.stakeReputation(beneficiary, _stakedReputation);

        status = Status.AwaitingSubmission;
    }

    function submit(
        bytes32 _submission,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
        ) 
        external 
        onlyWhen(Status.AwaitingSubmission) 
    {
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            domain_separator,
            keccak256(abi.encode(SUBMIT_TYPEHASH, _submission))
        ));

        require(beneficiary != address(0));
        require(beneficiary == ecrecover(digest, _v, _r, _s), "invalid-permit");

        status = Status.AwaitingReview;
    }

    function review(
        bool _approve,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
        ) 
        external 
        onlyWhen(Status.AwaitingReview) 
    {
        require(msg.sender == depositor, "Reviewer must be the owner of the contract and the depositor of the escrow.");
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            domain_separator,
            keccak256(abi.encode(REVIEW_TYPEHASH, _approve))
        ));

        require(depositor == ecrecover(digest, _v, _r, _s), "invalid-permit");

        if (_approve) {
            resolve(beneficiary);
        } else {
            status = Status.AwaitingSubmission;
        }
    }

    function resolve() 
        private 
    {
        require(beneficiary != address(0));

        daiToken.push(beneficiary, daiToken.balanceOf(address(this)));
        status = Status.Approved;
        state = ContractState.Locked
    }

    function getExchangeStatus() 
        public 
    {
        return status;
    }
    
    function getExchangeState() 
        public 
    {
        return state;
    }
}