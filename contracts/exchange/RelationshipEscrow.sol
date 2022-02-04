pragma solidity 0.8.7;

import "../dispute/interface/IArbitrable.sol";
import "../dispute/interface/IEvidence.sol";
import "./interface/IDaiToken.sol";
import "../libraries/RelationshipLibrary.sol";

contract RelationshipEscrow is IArbitrable, IEvidence {
    IArbitrator arbitrator;

    constructor(address _arbitrator) {
        arbitrator = _arbitrator;
    }

    enum RulingOptions {
        EmployerWins,
        WorkerWins
    }

    enum ContractType {
        FlatRate,
        Milestone,
        Stream
    }

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

    error InvalidStatus();
    error ReleasedTooEarly();
    error NotPayer();
    error NotArbitrator();
    error ThirdPartyNotAllowed();
    error PayeeDepositStillPending();
    error ReclaimedTooLate();
    error InsufficientPayment(uint256 _available, uint256 _required);
    error InvalidRuling(uint256 _ruling, uint256 _numberOfChoices);

    struct RelationshipEscrowDeteails {
        address payable payer;
        address payable payee;
        IArbitrator arbitrator;
        Status status;
        uint256 value;
        uint256 disputeID;
        uint256 createdAt;
        uint256 reclaimedAt;
        uint256 payerFeeDeposit;
        uint256 payeeFeeDeposit;
        uint256 arbitrationFeeDepositPeriod;
    }

    uint256 constant numberOfRulingOptions = 2;
    uint256 public constant arbitrationFeeDepositPeriod = 3 minutes; // Timeframe is short on purpose to be able to test it quickly. Not for production use.
    mapping(uint256 => uint256) public disputeIDtoRelationshipID;
    IDaiToken daiToken;
    RelationshipEscrowDetails[] public relationshipEscrowDetails;

    function initialize(
        address _payer,
        address payable _payee,
        string memory _metaevidence,
        uint256 _wad,
        uint256 _nonce,
        uint256 _expiry,
        uint8 _vAllow,
        bytes32 _rAllow,
        bytes32 _sAllow,
        uint8 _vDeny,
        bytes32 _rDeny,
        bytes32 _sDeny
    ) external {
        Relationship relationship = new Relationship(msg.sender);
        require(relationship.contractState == ContractState.Unitialized);

        emit MetaEvidence(relationshipEscrowDetails.length, _metaevidence);

        relationshipEscrowDetails[
            relationship.relationshipID()
        ] = RelationshipEscrowDetails({
            payer: _payer,
            payee: _payee,
            status: Status.Initial,
            value: _wad,
            disputeID: keccak256(relationshipID),
            createdAt: block.timestamp,
            reclaimedAt: 0,
            payerFeeDeposit: 0,
            payeeFeeDeposit: 0,
            arbitrationFeeDepositPeriod: arbitrationFeeDepositPeriod
        });

        // Unlock buyer's Dai balance to transfer `wad` to this contract.
        daiToken.permit(_payer, address(this), nonce, expiry, true, v, r, s);

        // Transfer Dai from `buyer` to this contract.
        daiToken.pull(_payer, _wad);

        // Relock Dai balance of `buyer`.
        daiToken.permit(
            _payer,
            address(this),
            nonce + 1,
            expiry,
            false,
            vDeny,
            rDeny,
            sDeny
        );
    }

    function releaseFunds(uint256 _amount) external {
        Relationship relationship = new Relationship(msg.sender);
        require(tx.origin == relationship.owner());

        RelationshipEscrowDetails
            storage escrowDetails = relationshipEscrowDetails[
                relationship.relationshipID()
            ];

        if (relationship.contractState != ContractState.Initialized) {
            revert InvalidStatus();
        }

        escrowDetails.status = Approved;

        daiToken.transfer(escrowDetails.payee, _amount);
        escrowDetails.value = escrowDetails.value - _amount;
    }

    function reclaimUnclaimedFunds() external {
        Relationship relationship = Relationship(msg.sender);
        require(relationship.contractOwnership == ContractOwnership.UNCLAIMED);

        daiToken.transfer(escrowDetails.payer, escrowDetails.value);
        escrowDetails.value = 0;
    }

    function reclaimFunds() external payable {
        Relationship relationship = Relationship(msg.sender);
        require(tx.origin == relationship.owner());

        RelationshipEscrowDeteails escrowDetails = relationshipEscrowDetails[
            relationship.relationshipID()
        ];

        if (relationship.contractOwnership != ContractOwnership.CLAIMED) {
            revert InvalidStatus();
        }

        if (tx.origin != escrowDetails.payer) {
            revert NotPayer();
        }

        if (escrowDetails.status == Status.Reclaimed) {
            if (
                block.timestamp - escrowDetails.reclaimedAt <=
                escrowDetails.arbitrationFeeDepositPeriod
            ) {
                revert PayeeDepositStillPending();
            }

            daiToken.transfer(
                escrowDetails.payee,
                escrowDetails.value + escrowDetails.payerFeeDeposit
            );
            escrowDetails.value = 0;
            escrowDetails.status = Status.Resolved;

            relationship.notifyClaimedContract(
                uint256(RelationshipLibrary.ContractStatus.Approved)
            );
        } else {
            uint256 requiredAmount = escrowDetails.arbitrator.arbitrationCost(
                ""
            );
            if (msg.value < requiredAmount) {
                revert InsufficientPayment(msg.value, requiredAmount);
            }

            escrowDetails.payerFeeDeposit = msg.value;
            escrowDetails.reclaimedAt = block.timestamp;
            escrowDetails.status = Status.Reclaimed;

            //tell relationship it is disputed
            relationship.notifyClaimedContract(
                uint256(RelationshipLibrary.ContractStatus.Disputed)
            );
        }
    }

    function depositArbitrationFeeForPayee(uint256 _relationshipID)
        external
        payable
    {
        RelationshipEscrowDetails
            storage escrowDetails = relationshipEscrowDetails[_relationshipID];

        if (escrowDetails.status != Status.Reclaimed) {
            revert InvalidStatus();
        }

        escrowDetails.payeeFeeDeposit = msg.value;
        escrowDetails.disputeID = escrowDetails.arbitrator.createDispute{
            value: msg.value
        }(numberOfRulingOptions, "");
        escrowDetails.status = Status.Disputed;
        disputeIDtoRelationshipID[escrowDetails.disputeID] = _relationshipID;
        emit Dispute(
            escrowDetails.arbitrator,
            escrowDetails.disputeID,
            _relationshipID,
            _relationshipID
        );
    }

    function rule(uint256 _disputeID, uint256 _ruling) public override {
        uint256 relationshipID = disputeIDtoRelationshipID[_relationshipID];
        RelationshipEscrowDetails
            storage escrowDetails = relationshipEscrowDetails[relationshipID];

        if (msg.sender != address(escrowDetails.arbitrator)) {
            revert NotArbitrator();
        }
        if (escrowDetails.status != Status.Disputed) {
            revert InvalidStatus();
        }
        if (_ruling > numberOfRulingOptions) {
            revert InvalidRuling(_ruling, numberOfRulingOptions);
        }
        escrowDetails.status = Status.Resolved;

        if (_ruling == uint256(RulingOptions.PayerWins))
            escrowDetails.payer.send(
                escrowDetails.value + escrowDetails.payerFeeDeposit
            ); 
        else
            escrowDetails.payee.send(
                escrowDetails.value + escrowDetails.payeeFeeDeposit
            ); 
        emit Ruling(escrowDetails.arbitrator, _disputeID, _ruling);

        relationship.notifyClaimedContract(
            uint256(RelationshipLibrary.ContractStatus.Approved)
        );
    }

    function submitEvidence(uint256 _relationshipID, string memory _evidence)
        public
    {
        RelationshipEscrowDetails
            storage escrowDetails = relationshipEscrowDetails[_relationshipID];

        if (escrowDetails.status == Status.Resolved) {
            revert InvalidStatus();
        }

        if (
            msg.sender != escrowDetails.payer &&
            msg.sender != escrowDetails.payee
        ) {
            revert ThirdPartyNotAllowed();
        }

        emit Evidence(
            escrowDetails.arbitrator,
            _relationshipID,
            msg.sender,
            _evidence
        );
    }

    function remainingTimeToDepositArbitrationFee(uint256 _relationshipID)
        external
        view
        returns (uint256)
    {
        RelationshipEscrowDetails
            storage escrowDetails = relationshipEscrowDetails[_relationshipID];

        if (escrowDetails.status != Status.Reclaimed) {
            revert InvalidStatus();
        }
        return
            (block.timestamp - escrowDetails.reclaimedAt) >
                escrowDetails.arbitrationFeeDepositPeriod
                ? 0
                : (escrowDetails.reclaimedAt +
                    escrowDetails.arbitrationFeeDepositPeriod -
                    block.timestamp);
    }
}
