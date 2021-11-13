// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../exchange/WorkRelationship.sol";
import "../exchange/interface/IDaiToken.sol";
import "../libraries/Transaction.sol";
import "../controller/interface/SchedulerInterface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract Dispute {
        struct Arbitrator {
        address universalAddress;
        address vote;
        bool voted;
    }
    
    mapping(address => Arbitrator) public addressToArbitrator;
    mapping(address => uint) public addressToReputationStake;
    address[] public arbitrators;

    uint immutable public startDate;
    uint public constant DISPUTE_STAKE = 5;

    bytes32 immutable public complaintMetadataPointer;
    bytes32 immutable public complaintResponseMetadataPointer;
    

    SchedulerInterface public scheduler;

    // keccak256("initializeDispute(address aggressor)")
    bytes32 public constant INITIALIZE_DISPUTE_TYPEHASH = 0xa5a0f8d2bd9a801d7bf3de4cb7f728cdbb90e91a22e6db05e58dd4a9b0bd280e;
    bytes32 public immutable domain_separator;

    enum DisputeStatus {
        AWAITING_ARBITRATORS,
        PENDING_DECISION,
        RESOLVED
    }

    address immutable relationship;
    uint numVotes = 0;
    DisputeStatus disputeStatus;

    event DisputeCreated(address indexed _employer, address indexed _worker, address indexed _relationship, address _dispute);
    event DisputeResolved(address indexed _relationship);
    event DisputeVote(address indexed _arbitrator, address indexed _relationship, address _vote);

    modifier onlyWhenStatus(DisputeStatus _disputeStatus) {
        require(_disputeStatus == disputeStatus);
        _;
    }

    constructor(
        address _relationship,
        address _scheduler,
        bytes32 _complaintMetadataPointer,
        bytes32 _complaintResponseMetadataPointer
    ) {
        require(_relationship != address(0));
        relationship = _relationship;
        disputeStatus = DisputeStatus.AWAITING_ARBITRATORS;

        startDate = block.timestamp;

        WorkRelationship workRelationship = WorkRelationship(_relationship);
        scheduler = SchedulerInterface(_scheduler);
        complaintMetadataPointer = _complaintMetadataPointer;
        complaintResponseMetadataPointer = _complaintResponseMetadataPointer;

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
            0,
            0,
            200000,
            0,
            0
        );

        payment = scheduler.schedule.value(endowment)( // 0.1 ether is to pay for gas, bounty and fee
            this,                   // send to self
            "",                     // and trigger fallback function
            [
                200000,             // The amount of gas to be sent with the transaction.
                0,                  // The amount of wei to be sent.
                255,                // The size of the execution window.
                lockedUntil,        // The start of the execution window.
                0,    // The gasprice for the transaction (aka 20 gwei)
                0,    // The fee included in the transaction.
                0,         // The bounty that awards the executor of the transaction.
                0 * 2     // The required amount of wei the claimer must send as deposit.
            ]
        );*/

        initializeDispute(workRelationship.owner(), workRelationship.worker(), _relationship);
    }

    function initializeDispute(address owner, address worker, address _relationship)
    internal {
        //TODO sign transaction as the aggressor

        //emit creation
        emit DisputeCreated(owner, worker, _relationship, address(this));
    }

    function joinDispute(
        Transaction.EIP712ERC20Permit calldata allow,
        Transaction.EIP712ERC20Permit calldata deny
    ) 
    external 
    onlyWhenStatus(DisputeStatus.AWAITING_ARBITRATORS)
    returns(int) 
    {
        require(arbitrators.length < 5, "The total number of arbitrators have been collected for this contract");

        WorkRelationship disputedRelationship = WorkRelationship(relationship);

        /**************** *************/
        //  Pull DAI from user account
        /*********** ******************/
        DaiToken daiToken = DaiToken(disputedRelationship.getRewardAddress());

        // Unlock buyer's Dai balance to transfer `wad` to this contract.
        daiToken.permit(disputedRelationship.owner(), address(this), allow.nonce, allow.expiry, true, allow.v, allow.r, allow.s);

        // Transfer Dai from `buyer` to this contract.
        daiToken.pull(disputedRelationship.owner(), DISPUTE_STAKE);

        // Relock Dai balance of `buyer`.
        daiToken.permit(disputedRelationship.owner(), address(this), allow.nonce + 1, deny.expiry, false, deny.v, deny.r, deny.s);

        acceptJoinRequest(msg.sender);
    }

    function acceptJoinRequest(address _requester) internal {
        Arbitrator memory newArbitrator = Arbitrator(address(0), address(0), false);

        addressToArbitrator[_requester] = newArbitrator;
        addressToReputationStake[_requester] = DISPUTE_STAKE;
        arbitrators.push(_requester);
    }

    function resolveDispute(address _relationship) internal {
        uint8 employerVotes = 0;
        uint8 workerVotes = 0;

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
            resolveDisputedRelationship(workRelationship.owner(), employerVotes);
        } else {
            resolveDisputedRelationship(workRelationship.worker(), workerVotes);
        }

        disputeStatus = DisputeStatus.RESOLVED;
        emit DisputeResolved(_relationship);
    }

    function resolveDisputedRelationship(address _winner, uint8 numWinnerVotes) internal {
        WorkRelationship workRelationship = WorkRelationship(relationship);
        workRelationship.resolveDisputedReward(_winner);

        uint totalArbitratorPayout = 0;
        for (uint i = 0; i < arbitrators.length; i++) {
            totalArbitratorPayout = SafeMath.add(totalArbitratorPayout, addressToReputationStake[arbitrators[i]]);
        }

        uint totalWinnerSplit = SafeMath.div(totalArbitratorPayout, numWinnerVotes);

        WorkRelationship disputedRelationship = WorkRelationship(relationship);
        DaiToken daiToken = DaiToken(disputedRelationship.getRewardAddress());

        for (uint i = 0; i < numVotes; i++) {
            if (addressToArbitrator[arbitrators[i]].voted == true 
                && _winner == addressToArbitrator[arbitrators[i]].vote) {
                
                daiToken.transfer(arbitrators[i], totalWinnerSplit);

            }
        }
    } 


    /*function vote(address vote) 
    external 
    onlyWhenStatus(DisputeStatus.PENDING_DECISION)
    {
        Arbitrator memory voter = addressToArbitrator[msg.sender];
        require(voter.voted == false, "You have already voted in this dispute.");

        voter.vote = vote;
        voter.voted = true;
        numVotes += numVotes;

        if (numVotes == 5) {
            resolveDispute(relationship);
        }
    }*/

    function checkDisputeArbitration() external returns(int) {
        if (startDate >= (startDate + 3 days)) {
            for (uint i = 0; i < arbitrators.length; i++) {
                Arbitrator memory arbitratorAddress = addressToArbitrator[arbitrators[i]];

                if (addressToArbitrator[arbitrators[i]].voted == false) {
                    addressToArbitrator[arbitrators[i]] = Arbitrator(address(0), address(0), false);
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