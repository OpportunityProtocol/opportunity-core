// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../exchange/WorkRelationship.sol";
import "../exchange/interface/IDaiToken.sol";
import "../libraries/Transaction.sol";
import "../libraries/Relationship.sol";

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

    bytes32 public complaintMetadataPointer;
    bytes32 public complaintResponseMetadataPointer;

    address relationship;
    string processId;

    uint8 constant NUM_JURY_MEMBERS = 5;
    uint8 constant max = 10; //??

    address juryProof;
    address immutable juryOversight;

    DisputeStatus disputeStatus;

    enum DisputeStatus {
        AWAITING_COMPLAINT_RESPONSE,
        AWAITING_ARBITRATORS,
        AWAITING_PROCESS_ID,
        PENDING_DECISION,
        RESOLVED
    }

    modifier onlyWhenStatus(DisputeStatus _disputeStatus) {
        require(_disputeStatus == disputeStatus);
        _;
    }

    modifier onlyArbitrator(sender) {
        require(addressToArbitrator[sender] != address(0), "Only arbitrators may call this function.");
        _;
    }

    modifier onlyFromAggressor(sender) {
        require(aggressor == sender, "Only the dispute aggressor can call this function.");
        _;
    }

    modifier onlyNonAggressor(sender) {
        WorkRelationship workRelationship = WorkRelationship(relationship);
        require(sender == workRelationship.owner() || sender == workRelationship.worker(), "The sender of this function must be the contract owner or worker.");
        require(sender != aggressor, "The sender of this function cannot be the aggressor.")
        _;
    }


    constructor(
        address _relationship,
        address _juryOversight,
        bytes32 _complaintMetadataPointer,
    ) {
        console.log('Dispute::constructor');
        require(_relationship != address(0));
        require(_juryOversight != address(0));
        //TODO: Only allow this to init if the relationship is in disputed state
        WorkRelationship workRelationship = WorkRelationship(relationship);
        require(workRelationship.contractStatus == Relationship.ContractStatus.Disputed);
        relationship = _relationship;
        juryOversight = _juryOversight;
        complaintMetadataPointer = _complaintMetadataPointer;
        WorkRelationship workRelationship = WorkRelationship(relationship);
        stake = 0; //calculate dispute stake

        disputeStatus = DisputeStatus.AWAITING_COMPLAINT_RESPONSE;

        startDate = block.timestamp;
        votingRoundStart = block.timestamp;
        aggressor = msg.sender;

        //emit creation
        emit DisputeCreated(
            workRelationship.owner(),
            workRelationship.worker(),
            _relationship,
            address(this)
        );

        emit ArbitrationWindowOpened(address(this));
    }

    function forfeitDispute() external {}

    function submitComplaintResponse(bytes32 _complaintResponseMetadataPointer) 
    onlyNonAggressor
    external 
    {
        complaintResponseMetadataPointer = _complaintResponseMetadataPointer;
        disputeStatus = DisputeStatus.AWAITING_ARBITRATORS;
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
        console.log('Dispute::joinDispute');
        require(arbitrators.length < NUM_JURY_MEMBERS);

        WorkRelationship disputedRelationship = WorkRelationship(relationship);

        /**************** *************/
        //  Pull DAI from user account
        /*********** ******************/
        DaiToken daiToken = DaiToken(disputedRelationship.getRewardAddress());

        // Unlock buyer's Dai balance to transfer `wad` to this contract.
        daiToken.permit(
            msg.sender,
            address(this),
            allow.nonce,
            allow.expiry,
            true,
            allow.v,
            allow.r,
            allow.s
        );

        // Transfer Dai from `buyer` to this contract.
        uint arbStake = 1;
        daiToken.pull(msg.sender, arbStake);
        stake += arbStake;

        // Relock Dai balance of `buyer`.
        daiToken.permit(
            msg.sender,
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
    {
        console.log('Dispute::exitDispute');
    }

    function acceptJoinRequest(address _requester) internal {
        console.log('Dispute::acceptJoinRequest');
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
        console.log('Dispute::resolveDisputedRelationship');
        WorkRelationship workRelationship = WorkRelationship(relationship);

        if (_winner == address(0)) {
            workRelationship.resolveTiedDisputedReward();
        } else {
            workRelationship.resolveDisputedReward(_winner);
        }

        uint256 totalArbitratorPayout = 0;
        uint256 totalWinnerSplit = 0;
        WorkRelationship disputedRelationship = WorkRelationship(relationship);
        DaiToken daiToken = DaiToken(disputedRelationship.getRewardAddress());

        //TODO: calc who voted for who

        //count the total num of arbs that voted for the winner
        totalArbitratorPayout++;
        daiToken.transfer(arbitrators[i], totalWinnerSplit);

        emit StakeResolved(address(this));
        emit DisputeResolved(relationship, round);
        disputeStatus = DisputeStatus.RESOLVED;
    }

    /** Anyone can call checkDispute.. if vote not resolved after 7 days then reset */
    function checkDispute(address vocdoniResultsAddress) external {
        console.log('Dispute::checkDispute');
        //check vote status
        

        //if vote not resolved after 7 days then reset
        if (/* vote not resolved  &&*/ votingRoundStart== votingRoundStart + 7 days) {
            resetAndStartDispute(processId);
        } else {
            //check results
        bytes memory payload = abi.encodeWithSignature("getResults(bytes32)", processId);
        console.log('Payload returned from abi.encodeWithSignature("getResults(bytes32)", processId): ' + payload);

         (bool success, bytes memory returnData) = address(vocdoniResultsAddress).call(payload);
         require(success, "Unsuccessfull attempt to read resutls from VOCDONI_);

         uint256 optionOneVotes = returnData.tally[0][0]; //employer
         uint256 optionTwoVotes = returnData.tally[0][1]; //worker

         WorkRelationship workRelationship = WorkRelationship(relationship);
         if (optionOneVotes > optionTwoVotes) {
             resolveDisputedRelationship(workRelationship.owner());
         } else if (optionTwoVotes < optionOneVotes) {
             resolveDisputedRelationship(workRelationship.worker());
         } else {
             resolveDisputedRelationship(address(0));
         }

        }
    }

    function verifyArbitratorCount() internal returns (int256) {
        console.log('Dispute::verifyArbitratorCount');
        if (arbitrators.length == NUM_JURY_MEMBERS) {
            disputeStatus = DisputeStatus.AWAITING_PROCESS_ID;

            JuryOversight oversight = JuryOversight(juryOversight);
            juryProof = oversight.setupJuryProof(relationship, address(this));
        }
    }

    /* Any arbitrator can call and this will release stake to all */
    function getStake() external onlyArbitrator() onlyWhenStatus(DisputeStatus.RESOLVED) {
        console.log('Dispute::getStake');
    }

    function processArbitratorNonVotePenalty() internal {
        console.log('Dispute::processArbitratorNonVotePenalty');
        //loop through votes

        //find all voters who didn't vote

        //keep their stake and redistribitue others

        //clear arb list
        
        uint256 amount = 0;

        emit PenaltyProcessed(voter, address(this), amount);
    }

    function newProcessId(string memory processId) 
    onlyWhenStatus(DisputeStatus.AWAITING_PROCESS_ID)
    onlyFromAggressor(msg.sender) 
    external {
        console.log('Dispute::newProcessId');
        //TODO:check if this process has this dispute address in the metadata

        //check the round
        if (round == 1) {
            require(msg.sender == aggressor, "The aggressor must submit the process id");

            processId = processId;
            startDispute(processId);
        } else {
            //too much time has passed.. anyone can call and refund
             if (block.timestamp >= (votingRoundStart + 7 days)) {
                cancelDisputeAndRefundOwner();
                return;
             }

            WorkRelationship workRelationship = WorkRelationship(relationship);
            require(msg.sender == workRelationship.owner() || msg.sender == workRelationship.worker(), "The process id must come from one of the disputers.");

            processId = processId;
            startDispute(processId);
        }
    }

    function submitVoteStatus() onlyArbitrator external {
        //mark msg.sender voter as voted
    }

    function cancelDisputeAndRefundOwner() internal {
        console.log('Dispute::cancelDisputeAndRefundOwner');
    }

    function resetAndStartDispute(string memory processId) 
    internal 
    {
        console.log('Dispute::resetAndStartDispute');
        disputeStatus = DisputeStatus.AWAITING_ARBITRATORS;
        emit ArbitrationWindowOpened(address(this));
        round = round + 1;

        processArbitratorNonVotePenalty();
        emit NewRound(address(this), round, processId, block.timestamp);
    }

    function startDispute(string memory processId) internal {
        //issue tokens to arbitrators


        //set status
        disputeStatus = DisputeStatus.PENDING_DECISION;
    }
}
