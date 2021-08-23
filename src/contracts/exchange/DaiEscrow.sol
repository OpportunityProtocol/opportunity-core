//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ILendingPool.sol";

/// Dai Token Interface
interface DaiToken {
    function balanceOf(address tokenOwner) external view returns (uint256);

    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function pull(address usr, uint wad) external;
    function push(address usr, uint wad) external;
    function approve(address usr, uint wad) external returns (bool);
}

// / @author Vypo Mouse (Forked and modified by Elijah Hampton) - https://forum.openzeppelin.com/t/feedback-on-dai-escrow-contract-that-reimburses-a-relayer-using-uniswap/2771
// / @title DaiEscrow
// / @notice Holds Dai tokens in escrow until the buyer and seller agree to
// /         release them. A relayer handles paying the transaction fees, and is
// /         reimbursed when the funds are released.
// / @dev First construct the contract, specifying the buyer and seller addresses.
// /      Then `initialize` the contract with signatures for Dai's `permit`. This
// /      transfers Dai from the buyer to the escrow contract.
// /
// /      When the seller has completed their responsibilities, the relayer
// /      calls `submit` on their behalf. If the seller does not complete their
// /      tasks within ~30 days, anyone may call `submitPastDue` and refund the
// /      buyer.
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
        AwaitingWad,
        AwaitingSubmission,
        AwaitingReview,
        Complete,
        Locked
    }
    // keccak256("Review(bool _approve)")
    bytes32 public constant REVIEW_TYPEHASH = 0xfa5e0016fb62b8dffda8fd95249d438edcffd3689b40ac3b4281d4cf710609ae;

    // keccak256("Submit(bytes32 _submission)")
    bytes32 public constant SUBMIT_TYPEHASH = 0x62b607caa4d4e7fcbd31bf4c033cd30888b536567fadc83710fdf15f8d5cfc9e;

    bytes32 public immutable domain_separator;

    address immutable public beneficiary;
    address immutable public depositor;

    uint immutable public wad;

    Status public status;

    DaiToken daiToken;

    modifier onlyWhen(Status _status) {
        require(status == _status, "Fn not presently valid");
        _;
    }

    constructor(
        address _beneficiary,
        address _depositor,
        uint _wad,
        address _daiTokenAddress
    ) public {
        require(_depositor != address(0), "invalid owner");
        require(_beneficiary != address(0), "invalid worker");
        require(_daiTokenAddress != address(0), "invalid dai token address");

        uint8 chain_id;
        assembly {
            chain_id := chainid()
        }

        domain_separator = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("escrow")),
            keccak256(bytes("1")),
            chain_id,
            address(this)
        ));

        wad = _wad;
        depositor = _depositor;
        beneficiary = _beneficiary;
        status = Status.AwaitingWad;
        daiToken = DaiToken(_daiTokenAddress);
    }

    function getEscrowStatus() {
        return status;
    }

    function initialize(
        uint256 nonce,
        uint256 expiry,
        uint8 v_allow,
        bytes32 r_allow,
        bytes32 s_allow,
        uint8 v_deny,
        bytes32 r_deny,
        bytes32 s_deny
    ) external onlyWhen(Status.AwaitingWad) {
        status = Status.AwaitingSubmission;

        // Unlock buyer's Dai balance to transfer `wad` to this contract.
        DAI.permit(depositor, address(this), nonce, expiry, true, v_allow, r_allow, s_allow);

        // Transfer Dai from `buyer` to this contract.
        DAI.pull(depositor, wad);

        // Relock Dai balance of `buyer`.
        DAI.permit(depositor, address(this), nonce + 1, expiry, false, v_deny, r_deny, s_deny);
    }

    function submit(
        bytes32 _submission,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external onlyWhen(Status.AwaitingSubmission) {
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            domain_separator,
            keccak256(abi.encode(SUBMIT_TYPEHASH, _submission))
        ));

        require(beneficiary == ecrecover(digest, _v, _r, _s), "invalid-permit");

        status = Status.AwaitingReview;
    }

    function review(
        bool _approve,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external onlyWhen(Status.AwaitingReview) {
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            domain_separator,
            keccak256(abi.encode(REVIEW_TYPEHASH, _approve))
        ));

        require(depositor == ecrecover(digest, _v, _r, _s), "invalid-permit");

        if (_approve) {
            resolve(beneficiary);
        } else {
            resolve(address(0));
        }
    }

    function resolve(address dai_target) private {
        bool locked = dai_target == address(0);

        if (locked) {
            status = Status.Locked;
        } else {
            status = Status.Complete;
        }

        if (!locked) {
            DAI.push(dai_target, DAI.balanceOf(address(this)));
        }
    }

    function cancel() external {
        require(status == Status.AwaitingWad || status == Status.Complete, "wrong status");
    }
}