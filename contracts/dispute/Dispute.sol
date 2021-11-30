// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../exchange/WorkRelationship.sol";
import "../exchange/interface/IDaiToken.sol";
import "../libraries/Transaction.sol";
import "../controller/interface/SchedulerInterface.sol";

contract Dispute {
    event DisputeCreated(
        address indexed _employer,
        address indexed _worker,
        address indexed _relationship,
        address _dispute
    );
    event DisputeResolved(address indexed _relationship);
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
    event VoteProcessed(address indexed voter, address dispute);

    struct Arbitrator {
        address universalAddress;
        address vote;
        bool voted;
    }

    mapping(address => Arbitrator) public addressToArbitrator;
    mapping(address => uint256) public addressToReputationStake;
    address[] public arbitrators;

    uint256 public immutable startDate;
    uint256 public votingStartDate;
    uint256 public immutable DISPUTE_STAKE;

    bytes32 public immutable complaintMetadataPointer;
    bytes32 public immutable complaintResponseMetadataPointer;

    address public immutable VOCDONI_PROCESS;// = "processes.vocdoni.eth";
    address public immutable VOCDONI_RESULTS;// = "results.vocdoni.eth";

    uint8 verifyRoundCount;
    SchedulerInterface public scheduler;

    enum DisputeStatus {
        AWAITING_ARBITRATORS,
        PENDING_DECISION,
        RESOLVED
    }

    address immutable relationship;
    address immutable processId;

    uint256 numVotes = 0;
    DisputeStatus disputeStatus;

    modifier onlyWhenStatus(DisputeStatus _disputeStatus) {
        require(_disputeStatus == disputeStatus);
        _;
    }

    modifier onlyEAC() {
        _;
    }

    constructor(
        address _relationship,
        address _scheduler,
        bytes32 _complaintMetadataPointer,
        bytes32 _complaintResponseMetadataPointer,
        string memory _processId
    ) {
        require(_relationship != address(0));
        relationship = _relationship;
        processId = address(0);//_processId;
        VOCDONI_PROCESS = address(0);
        VOCDONI_RESULTS = address(0);
        disputeStatus = DisputeStatus.AWAITING_ARBITRATORS;

        startDate = block.timestamp;

        WorkRelationship workRelationship = WorkRelationship(_relationship);
        scheduler = SchedulerInterface(_scheduler);
        complaintMetadataPointer = _complaintMetadataPointer;
        complaintResponseMetadataPointer = _complaintResponseMetadataPointer;

        //calculate dispute stake
        DISPUTE_STAKE = 0;

        //emit creation
        emit DisputeCreated(
            workRelationship.owner(),
            workRelationship.worker(),
            _relationship,
            address(this)
        );
        //emit ArbitrationWindowOpened();
    }

    function joinDispute(
        Transaction.EIP712ERC20Permit calldata allow,
        Transaction.EIP712ERC20Permit calldata deny
    )
        external
        onlyWhenStatus(DisputeStatus.AWAITING_ARBITRATORS)
        returns (int256)
    {
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
        daiToken.pull(disputedRelationship.owner(), DISPUTE_STAKE);

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

        if (block.timestamp >= startDate + 7 days && arbitrators.length >= 5) {
            disputeStatus = DisputeStatus.PENDING_DECISION;
        }
    }

    //exit a dispute as long as the dispute is in awaiting arbitration phase
    function exitDispute()
        external
        onlyWhenStatus(DisputeStatus.AWAITING_ARBITRATORS)
    {}

    function acceptJoinRequest(address _requester) internal {
        Arbitrator memory newArbitrator = Arbitrator(
            address(0),
            address(0),
            false
        );

        addressToArbitrator[_requester] = newArbitrator;
        addressToReputationStake[_requester] = DISPUTE_STAKE;
        arbitrators.push(_requester);
    }

    function resolveDisputedRelationship(address _winner) internal {
        WorkRelationship workRelationship = WorkRelationship(relationship);

        if (_winner == address(0)) {
            workRelationship.resolveTiedDisputedReward();
        } else {
            workRelationship.resolveDisputedReward(_winner);
        }

        uint256 totalArbitratorPayout = 0;
        for (uint256 i = 0; i < arbitrators.length; i++) {
            totalArbitratorPayout =
                totalArbitratorPayout +
                addressToReputationStake[arbitrators[i]];
        }

        uint256 totalWinnerSplit = 0; /*= SafeMath.div(
            totalArbitratorPayout,
            numWinnerVotes
        );*/

        WorkRelationship disputedRelationship = WorkRelationship(relationship);
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
                    addressToReputationStake[arbitrators[i]]
                );
            }
        }

        emit StakeResolved(address(this));
        emit DisputeResolved(relationship);
         disputeStatus = DisputeStatus.RESOLVED;
    }

    function revealVote() internal {}

    function getStake() external {}

    function vote() external {
        address voter = msg.sender;

        Arbitr
    }


    /****************** REVISIT IF NEEDED OR ERASE  *******************/

    //check if the dispute has ended
    //eac should call this 3 days after arb window closes
    function checkDispute() external onlyWhenStatus(DisputeStatus.PENDING_DECISION) {
        //get status
      /*  uint status = 0;

        //if status is resolved
        if (status == 0) {
        bytes memory payload = abi.encodeWithSignature("getResults(bytes32)", processId);
        (bool success, bytes memory returnData) = address(VOCDONI_RESULTS).call(payload);
        require(success);

        uint256 optionOneVotes = returnData.tally[0][0];
        uint256 optionTwoVotes = returnData.tally[0][1];

        if (optionOneVotes > optionTwoVotes) {
            resolveDisputedRelationship(returnData.tally[0][0]);
        } else if (optionTwoVotes < optionOneVotes) {
            resolveDisputedRelationship(returnData.tally[0][1]);
        } else {
            resolveDisputedRelationship(0);
        }
        }*/
    }

    function verifyArbitrationCount() external onlyEAC returns (int256) {
        // if we are past the three day arbitration window
       /* if (startDate >= (startDate + 7 days)) {
            //change status to pending decision when we get 5 or more arbitrators
            if (arbitrators.length >= 5) {
                uint256 endowment = scheduler.computeEndowment(
                    0,
                    0,
                    200000,
                    0,
                    0
                );

                payment = scheduler.schedule.value(endowment)( // 0.1 ether is to pay for gas, bounty and fee
                    this, // send to self
                    checkDispute, // and trigger fallback function
                    [
                        200000, // The amount of gas to be sent with the transaction.
                        0, // The amount of wei to be sent.
                        255, // The size of the execution window.
                        (block.number + 7 days), // The start of the execution window.
                        0, // The gasprice for the transaction (aka 20 gwei)
                        0, // The fee included in the transaction.
                        0, // The bounty that awards the executor of the transaction.
                        0 * 2 // The required amount of wei the claimer must send as deposit.
                    ]
                );

                disputeStatus = DisputeStatus.PENDING_DECISION;
                emit ArbitrationWindowClosed();
            } else {
                //reschedule to check again in 7 days instead of the normal three to save gas
                //TODO: set scheduler to call veryify in 7 days
                uint256 endowment = scheduler.computeEndowment(
                    0,
                    0,
                    200000,
                    0,
                    0
                );

                payment = scheduler.schedule.value(endowment)( // 0.1 ether is to pay for gas, bounty and fee
                    this, // send to self
                    verifyArbitrationCount, // and trigger fallback function
                    [
                        200000, // The amount of gas to be sent with the transaction.
                        0, // The amount of wei to be sent.
                        255, // The size of the execution window.
                        block.number + 7 days, // The start of the execution window.
                        0, // The gasprice for the transaction (aka 20 gwei)
                        0, // The fee included in the transaction.
                        0, // The bounty that awards the executor of the transaction.
                        0 * 2 // The required amount of wei the claimer must send as deposit.
                    ]
                );

                verifyRoundCount += 1;
            }
        }*/
    }
}
