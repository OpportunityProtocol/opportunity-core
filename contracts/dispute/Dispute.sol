// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../exchange/WorkRelationship.sol";
import "../exchange/interface/IDaiToken.sol";
import "../libraries/Transaction.sol";

contract Dispute {
    event DisputeCreated(
        address indexed _employer,
        address indexed _worker,
        address indexed _relationship,
        address _dispute
    );
    event DisputeResolved(address indexed _relationship, uint8 round);
    event StakingWindowOpened(address indexed _dispute);
    event StakingWindowClosed(address indexed _dispute);
    event ArbitrationWindowOpened(address indexed _dispute);
    event ArbitrationWindowClosed(address indexed _dispute);
    event StakeResolved(address indexed _dispute);
    event PenaltyProcessed(
        address indexed voter,
        address indexed _dispute,
        uint256 _amount
    );
    event NewRound(address indexed dispute, uint256 indexed round, string processId, uint timestamp);


    struct Arbitrator {
        address universalAddress;
        bytes32 vote;
        uint64 blockNumber;
        bool voted;
        bool revealed;
    }

    mapping(address => Arbitrator) public addressToArbitrator;
    address[] public arbitrators;

    address immutable aggressor;
    uint256 public immutable startDate;
    uint256 public stake;

    uint8 public round = 1;
    uint256 public votingRoundStart;
    uint8 public numVotes; 
    uint256 public votingStartDate;

    bytes32 public immutable complaintMetadataPointer;
    bytes32 public immutable complaintResponseMetadataPointer;

    address relationship;
    string processId;

    uint8 constant NUM_JURY_MEMBERS = 5;
    uint8 constant max = 10; //??

    DisputeStatus disputeStatus;

    enum DisputeStatus {
        AWAITING_ARBITRATORS,
        AWAITING_PROCESS_ID,
        PENDING_DECISION,
        RESOLVED
    }

    modifier onlyWhenStatus(DisputeStatus _disputeStatus) {
        require(_disputeStatus == disputeStatus);
        _;
    }

    modifier onlyArbitrator() {
        _;
    }


    constructor(
        address _relationship,
        bytes32 _complaintMetadataPointer,
        bytes32 _complaintResponseMetadataPointer
    ) {
        require(_relationship != address(0));
        relationship = _relationship;
        disputeStatus = DisputeStatus.AWAITING_ARBITRATORS;
        startDate = block.timestamp;
        votingRoundStart = block.timestamp;
        aggressor = msg.sender;

        complaintMetadataPointer = _complaintMetadataPointer;
        complaintResponseMetadataPointer = _complaintResponseMetadataPointer;

        WorkRelationship workRelationship = WorkRelationship(relationship);

        //calculate dispute stake
        stake = 0;

        //emit creation
        emit DisputeCreated(
            workRelationship.owner(),
            workRelationship.worker(),
            _relationship,
            address(this)
        );

        emit ArbitrationWindowOpened(address(this));
    }

    /**
     * Anyone can use the joinDispute method to join a dispute.  The number of arbitrators has to
     * be less than 5 to join.
     *
     *
     */
    function joinDispute(
        Transaction.EIP712ERC20Permit calldata allow,
        Transaction.EIP712ERC20Permit calldata deny
    )
        external
        onlyWhenStatus(DisputeStatus.AWAITING_ARBITRATORS)
        returns (int256)
    {
        require(arbitrators.length < NUM_JURY_MEMBERS);

        WorkRelationship disputedRelationship = WorkRelationship(relationship);

        /**************** *************/
        //  Pull DAI from user account
        /*********** ******************/
        DaiToken daiToken = DaiToken(disputedRelationship.getRewardAddress());

        // Unlock buyer's Dai balance to transfer `wad` to this contract.
        daiToken.permit(
            disputedRelationship.owner(),
            address(this),
            allow.nonce,
            allow.expiry,
            true,
            allow.v,
            allow.r,
            allow.s
        );

        // Transfer Dai from `buyer` to this contract.
        daiToken.pull(disputedRelationship.owner(), stake);

        // Relock Dai balance of `buyer`.
        daiToken.permit(
            disputedRelationship.owner(),
            address(this),
            allow.nonce + 1,
            deny.expiry,
            false,
            deny.v,
            deny.r,
            deny.s
        );

        acceptJoinRequest(msg.sender);
        verifyArbitratorCount();
    }

    /**
     * Any arbitrator can call this method to leave a dispute.  This method can only
     * be called when we are in the arbitrator period.
     *
     */
    function exitDispute()
        external
        onlyArbitrator()
        onlyWhenStatus(DisputeStatus.AWAITING_ARBITRATORS)
    {}

    function acceptJoinRequest(address _requester) internal {
        Arbitrator memory newArbitrator = Arbitrator(
            address(0),
            '',
            0,
            false,
            false
        );

        addressToArbitrator[_requester] = newArbitrator;
        arbitrators.push(_requester);
    }


    function resolveDisputedRelationship(address _winner) internal {
      /*  WorkRelationship workRelationship = WorkRelationship(relationship);

        if (_winner == address(0)) {
            workRelationship.resolveTiedDisputedReward();
        } else {
            workRelationship.resolveDisputedReward(_winner);
        }

        uint256 totalArbitratorPayout = 0;
        for (uint256 i = 0; i < arbitrators.length; i++) {
            totalArbitratorPayout =
                totalArbitratorPayout +
                stake;
        }

        uint256 totalWinnerSplit = 0; /*= SafeMath.div(
            totalArbitratorPayout,
            numWinnerVotes
        );*/

        /*WorkRelationship disputedRelationship = WorkRelationship(relationship);
        DaiToken daiToken = DaiToken(disputedRelationship.getRewardAddress());

        for (uint256 i = 0; i < numVotes; i++) {
            if (
                addressToArbitrator[arbitrators[i]].voted == true &&
                addressToArbitrator[arbitrators[i]].vote == _winner
            ) {
                daiToken.transfer(arbitrators[i], totalWinnerSplit);
            } else {
                emit PenaltyProcessed(
                    arbitrators[i],
                    address(this),
                    stake
                );
            }
        }

        emit StakeResolved(address(this));
        emit DisputeResolved(relationship, round);
        disputeStatus = DisputeStatus.RESOLVED;*/
    }

    /** Anyone can call checkDispute.. if vote not resolved after 7 days then reset */
    function checkDispute() external {
        //check vote status

        //if vote not resolved after 7 days then reset
        if (/* vote not resolved  &&*/ votingRoundStart== votingRoundStart + 7 days) {
            resetAndStartDispute(processId);
        } else {
            //check results

            //resolve disputed winner

        }
    }

    function verifyArbitratorCount() internal returns (int256) {
        if (arbitrators.length == NUM_JURY_MEMBERS) {
            disputeStatus = DisputeStatus.PENDING_DECISION;
        }
    }

    function getStake() external onlyArbitrator() onlyWhenStatus(DisputeStatus.RESOLVED) {}

    function processArbitratorNonVotePenalty(
        address voter
    ) internal {
        uint256 amount = 0;

        emit PenaltyProcessed(voter, address(this), amount);
    }

    function newProcessId(string memory processId) onlyWhenStatus(DisputeStatus.AWAITING_PROCESS_ID) external {
        //check if this process has this dispute address in the metadata

        //check the round
        if (round == 1) {
            require(msg.sender == aggressor, "The aggressor must submit the process id");

            processId = processId;
            resetAndStartDispute(processId);
        } else {
            //too much time has passed.. anyone can call and refund
             if (block.timestamp >= (votingRoundStart + 7 days)) {
                cancelDisputeAndRefundOwner();
                return;
             }

            WorkRelationship workRelationship = WorkRelationship(relationship);
            require(msg.sender == workRelationship.owner() || msg.sender == workRelationship.worker(), "The process id must come from one of the disputers.");

            processId = processId;
            resetAndStartDispute(processId);
        }
    }

    function cancelDisputeAndRefundOwner() internal {

    }

    function resetAndStartDispute(string memory processId) 
    internal 
    {

        disputeStatus = DisputeStatus.AWAITING_ARBITRATORS;
        emit ArbitrationWindowOpened(address(this));

        //processArbitratorNonVotePenalty();
        emit NewRound(address(this), round + 1, processId, block.timestamp);
    }

}
