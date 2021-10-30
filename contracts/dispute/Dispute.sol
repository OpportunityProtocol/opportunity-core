// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../exchange/WorkRelationship.sol";
import "contracts/Interface/SchedulerInterface.sol";

contract Dispute {
    mapping(address => Arbitrator) public addressToArbitrator;
    mapping(uint => address) public reputationStateToArbitratorAddress;
    address[] public arbitrators;

    uint immutable public startDate;

    SchedulerInterface public scheduler;

    // keccak256("initializeDispute(address aggressor)")
    bytes32 public constant INITIALIZE_DISPUTE_TYPEHASH = 0xa5a0f8d2bd9a801d7bf3de4cb7f728cdbb90e91a22e6db05e58dd4a9b0bd280e;
    bytes32 public immutable domain_separator;

    enum DisputeStatus {
        AWAITING_ARBITRATORS,
        PENDING_DECISION,
        RESOLVED
    }

    struct Arbitrator {
        address universalAddress;
        address vote;
        bool voted;
    }

    address immutable relationship;
    uint numVotes = 0;
    DisputeStatus disputeStatus;

    event DisputeCreated(address indexed _employer, address indexed _worker, address indexed _relationship, uint _startDate);
    event DisputeResolved(address indexed _relationship);
    event DisputeVote(address indexed _arbitrator, address indexed _relationship, address _vote);

    modifier onlyWhenStatus(DisputeStatus _disputeStatus) {
        require(_disputeStatus == disputeStatus);
        _;
    }

    constructor(
        address _relationship,
    ) {
        require(_relationship != address(0));
        relationship = _relationship;
        disputeStatus = DisputeStatus.AWAITING_ARBITRATORS;

        startDate = block.timestamp;

        WorkRelationship workRelationship = WorkRelationship(_relationship);
        scheduler = SchedulerInterface(_scheduler);

        uint8 chain_id;
        assembly {
            chain_id := chainid()
        }

        domain_separator = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("Dispute")),
            keccak256(bytes("1")),
            chain_id,
            address(this)
        ));

        //TODO: Complete scheduling
        /*uint endowment = scheduler.computeEndowment(
            twentyGwei,
            twentyGwei,
            200000,
            0,
            twentyGwei
        );

        payment = scheduler.schedule.value(endowment)( // 0.1 ether is to pay for gas, bounty and fee
            this,                   // send to self
            "",                     // and trigger fallback function
            [
                200000,             // The amount of gas to be sent with the transaction.
                0,                  // The amount of wei to be sent.
                255,                // The size of the execution window.
                lockedUntil,        // The start of the execution window.
                twentyGwei,    // The gasprice for the transaction (aka 20 gwei)
                twentyGwei,    // The fee included in the transaction.
                twentyGwei,         // The bounty that awards the executor of the transaction.
                twentyGwei * 2     // The required amount of wei the claimer must send as deposit.
            ]
        );*/

        initializeDispute();

        emit DisputeCreated(workRelationship.owner(), workRelationship.worker(), _relationship, startDate);
    }

    function initializeDispute()
    internal {
        //TODO sign transaction as the aggressor
    }

    function joinDispute() 
    external 
    onlyWhenStatus(DisputeStatus.AWAITING_ARBITRATORS)
    returns(int) 
    {
        require(addressToArbitrator.length < 5, "The total number of arbitrators have been collected for this contract");

        UserSummary user = new UserSummary(msg.sender);
        uint userReputation = user.reputation();

        //uint reputationStake = user.stakeReputation(0);

        if (true /* if user has the reputation to participate*/) {
            acceptJoinRequest(msg.sender, reputationStake);
            return -1;
        } else {
            return 0;
        }
    }

    function acceptJoinRequest(address _requester, uint reputationStake) internal {
        Arbitrator newArbitrator = Arbitrator(0, false);

        addressToArbitrator[_requester] = newArbitrator;
        reputationStakeToArbitratorAddress[_requester] = reputationStake;
    }

    function resolveDispute(address _relationship) internal {
        uint employerVotes = 0;
        uint workerVotes = 0;

        WorkRelationship workRelationship = WorkRelationship(_relationship);

        for (uint i = 0; i < numVotes; i++) {
            if (addressToArbitrator[arbitrators[i]].voted == true 
                && workRelationship.owner() == addressToArbitrator[arbitrators[i]].vote) {
                employerVotes += 1;
            } else {
                workerVotes += 1;
            }
        }

        //We ensure the votes are not equal by electing a new voter if an arbitrator fails to vote
        if (employerVotes > workerVotes) {
            resolveRelationship(workRelationship.owner());
        } else {
            resolveRelationship(workRelationship.worker());
        }

        disputeStatus = DisputeStatus.RESOLVED;
        emit DisputeResolved(_relationship);
    }

    function resolveRelationship(address _winner) internal {
        WorkRelationship workRelationship = WorkRelationship(relationship);
        workRelationship.resolveDisputedReward(_winner);
    } 


    function vote(address vote) 
    external 
    onlyWhenStatus(DisputeStatus.PENDING_DECISION)
    {
        Arbitrator voter = addressToArbitrator[msg.sender];
        require(voter.voted == false, "You have already voted in this dispute.");

        voter.vote = vote;
        voter.voted = true;
        numVotes += numVotes;

        if (numVotes == 5) {
            resolveDispute(relationship);
        }
    }

    function checkDisputeArbitration() external returns(int) {
        if (startDate >= (startDate + 3 days)) {
            for (uint i = 0; i < numVotes; i++) {
                if (addressToArbitrator[arbitrators[i]].voted == false) {
                    addressToArbitrator[arbitrators[i]] = 0;
                    delete arbitrators[i];
                }
            }

            if (arbitrators.length < 5) {
                return -1;
                disputeStatus = DisputeStatus.AWAITING_ARBITRATORS;
            } else {
                return 0;
            }
        }
    }
}