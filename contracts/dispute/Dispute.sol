// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../exchange/WorkRelationship.sol";
import "../exchange/interface/IDaiToken.sol";
import "./interface/IProcessResults.sol";
import "../libraries/Transaction.sol";
import "../controller/interface/SchedulerInterface.sol";

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
    event NewRound(address indexed dispute, uint256 indexed round);
    event RevealVote(address sender, bytes32 revealHash, uint8 random);
    event CommitVote(address sender, bytes32 dataHash, uint64 block);

    struct Arbitrator {
        address universalAddress;
        bytes32 vote;
        uint64 blockNumber;
        bool voted;
        bool revealed
    };

    mapping(address => Arbitrator) public addressToArbitrator;
    address[] public arbitrators;

    address immutable aggressor;
    uint256 public immutable startDate;
    uint256 public stake;

    uint8 public round;
    uint256 public votingRoundStart;
    uint8 public numVotes;

    bytes32 public immutable complaintMetadataPointer;
    bytes32 public immutable complaintResponseMetadataPointer;

    address immutable relationship;
    address immutable processId;

    uint8 constant NUM_JURY_MEMBERS = 5;

    DisputeStatus disputeStatus;

    enum DisputeStatus {
        AWAITING_ARBITRATORS,
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
        bytes32 _complaintResponseMetadataPointer,
        string _processId
    ) {
        require(_relationship != address(0));
        relationship = _relationship;
        processId = _processId;
        disputeStatus = DisputeStatus.AWAITING_ARBITRATORS;
        startDate = block.timestamp;
        votingRoundStart = block.timestamp;
        aggressor = msg.sender;

        complaintMetadataPointer = _complaintMetadataPointer;
        complaintResponseMetadataPointer = _complaintResponseMetadataPointer;

        WorkRelationship workRelationship = WorkRelationship(_relationship);

        //calculate dispute stake
        stake = 0;

        //emit creation
        emit DisputeCreated(
            workRelationship.owner(),
            workRelationship.worker(),
            _relationship,
            _processId
        );

        emit ArbitrationWindowOpened();
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

    /**
     * Anyone can call check dispute.  If someone calls check dispute who is not an arbitrator
     * then it must be after the recognized voting period has ended and in this case the dispute is
     * reset for another round.  If it is called by an arbitrator then we automatically resolve the dispute.
     * We know it is the last arbitrator to reveal because checkDispute can only be called by an arbitrator
     * if all of the votes have been revealed.
     */
    function checkDispute() public onlyWhen(DisputeStatus.PENDING_DECISION) {
        //if a non arbitrator calls check and it is one day after the voting period then we reset
        if (addressToArbitrator[msg.sender] == address(0)) {
            require(block.timestamp >= (votingRoundStart + 8 days));

            resetDispute();
        }

        if (addressToArbitrator[msg.sender] != address(0)) {
            require(numVotes == arbitrators.length);

            //count votes

            //resolve the winner
            resolveDisputedRelationship();
        }
    }

    function verifyArbitrationCount() external returns (int256) {}

    function getHash(bytes32 data) public view returns(bytes32){
        return keccak256(abi.encodePacked(address(this), data));
    }

    function commit(bytes32 dataHash, uint64 block_number) public {
        require(block_number > block.number,"This vote has already been revealed.");
        addressToArbitrator[msg.sender].vote = dataHash;
        addressToArbitrator[msg.sender].blockNumber = block_number;
        addressToArbitrator[msg.sender].revealed = false;
        console.log(block.number, block_number);
        emit CommitVote(msg.sender, addressToArbitrator[msg.sender].vote,addressToArbitrator[msg.sender].blockNumber);
    }

    function resetDispute() internal {}

    /**
     * The reveal method reveals an arbitrators vote.  An arbitrator can call reveal as long as the dispute
     * is still in the voting period.  If the dispute is past the voting period then we reset the dispute
     * for another round.  If the dispute is not past the voting period we allow an arbitrator to reveal.
     * Once the last arbitrator reveals then checkDispute is called to resolve the dispute.
     */
    function reveal(bytes32 revealHash) onlyArbitrator() public {
        if (block.timestamp >= votingRoundStart + 7 days) {
            resetDispute();
        }

        require(addressToArbitrator[msg.sender].revealed == false, "CommitReveal::reveal: This vote has already been revealed.");
        require(getHash(revealHash) == addressToArbitrator[msg.sender].vote, "CommitReveal::reveal: The revealed hash does not match the vote for this hash.");

        addressToArbitrator[msg.sender].revealed = true;

        bytes32 blockHash = blockhash(addressToArbitrator[msg.sender].blockNumber);
        uint8 random = uint8(uint(keccak256(abi.encodePacked(blockHash, revealHash)))) % max;
        numVotes++;

        //after the last person reveals their vote settle the dispute
        if (numVotes == arbitrators.length) {
            checkDispute();
        }

        emit RevealVote(msg.sender, revealHash, random);
        console.log("Random: ", random);
    }
}
