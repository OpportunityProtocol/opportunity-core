pragma solidity 0.8.7;

import "../dispute/interface/IArbitrable.sol";
import "../dispute/interface/IEvidence.sol";
import "./interface/IDaiToken.sol";
import "./interface/Relationship.sol";
import "../libraries/RelationshipLibrary.sol";
import "hardhat/console.sol";

contract RelationshipEscrow is IArbitrable, IEvidence {
    IArbitrator immutable arbitrator;
    DaiToken daiToken;

    constructor(address _arbitrator, address _daiToken) {
        arbitrator = IArbitrator(_arbitrator);
        daiToken = DaiToken(_daiToken);
    }

    enum RulingOptions {
        PayerWins,
        PayeeWins
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
    
    enum EscrowStatus {
        Initial,
        Reclaimed,
        Disputed,
        Resolved
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

    struct RelationshipEscrowDetails {
        address payer;
        address payee;
        IArbitrator arbitrator;
        EscrowStatus status;
        address relationshipAddress;
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
    mapping(uint256 => RelationshipEscrowDetails) public relationshipEscrowDetails;

    function initialize(
        address _payer,
        address _payee,
        string memory _metaevidence,
        uint256 _wad
    ) external {
        Relationship relationship = Relationship(msg.sender);

        require(uint256(relationship.contractState()) == uint256(ContractState.Uninitialized));

        emit MetaEvidence(relationship.relationshipID(), _metaevidence);
 
        relationshipEscrowDetails[
            relationship.relationshipID()
        ] = RelationshipEscrowDetails({
            payer: _payer,
            payee: _payee,
            arbitrator: arbitrator,
            status: EscrowStatus.Initial,
            relationshipAddress: msg.sender,
            value: _wad,
            disputeID: relationship.relationshipID(),
            createdAt: block.timestamp,
            reclaimedAt: 0,
            payerFeeDeposit: 0,
            payeeFeeDeposit: 0,
            arbitrationFeeDepositPeriod: arbitrationFeeDepositPeriod
        });
        console.log('Sender');
        console.log(msg.sender);
        daiToken.transferFrom(msg.sender, address(this), _wad);
    }

    function surrenderFunds() external {
        Relationship relationship = Relationship(msg.sender);
        require(tx.origin == relationship.worker());

        RelationshipEscrowDetails storage escrowDetails = relationshipEscrowDetails[relationship.relationshipID()];

        daiToken.transfer(escrowDetails.payer, escrowDetails.value);
    }

    function releaseFunds(uint256 _amount) external {
        Relationship relationship = Relationship(msg.sender);
        require(tx.origin == relationship.owner());

        RelationshipEscrowDetails
            storage escrowDetails = relationshipEscrowDetails[
                relationship.relationshipID()
            ];

        if (uint256(relationship.contractState()) != uint256(ContractState.Initialized)) {
            revert InvalidStatus();
        }

        escrowDetails.status = EscrowStatus.Resolved;

        daiToken.transfer(escrowDetails.payee, _amount);
        escrowDetails.value = escrowDetails.value - _amount;
    }

    function reclaimUnclaimedFunds() external {
        Relationship relationship = Relationship(msg.sender);
        require(uint256(relationship.contractOwnership()) == uint256(ContractOwnership.UNCLAIMED));

        RelationshipEscrowDetails storage escrowDetails = relationshipEscrowDetails[relationship.relationshipID()];
        daiToken.transfer(escrowDetails.payer, escrowDetails.value);
        escrowDetails.value = 0;
    }

    function reclaimFunds() external payable {
        Relationship relationship = Relationship(msg.sender);
        require(tx.origin == relationship.owner());

        RelationshipEscrowDetails storage escrowDetails = relationshipEscrowDetails[
            relationship.relationshipID()
        ];

        if (uint256(relationship.contractOwnership()) != uint256(ContractOwnership.CLAIMED)) {
            revert InvalidStatus();
        }

        if (tx.origin != escrowDetails.payer) {
            revert NotPayer();
        }

        if (escrowDetails.status == EscrowStatus.Reclaimed) {
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
            escrowDetails.status = EscrowStatus.Resolved;

            relationship.notifyContract(
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
            escrowDetails.status = EscrowStatus.Reclaimed;

            //tell relationship it is disputed
            relationship.notifyContract(
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

        if (escrowDetails.status != EscrowStatus.Reclaimed) {
            revert InvalidStatus();
        }

        escrowDetails.payeeFeeDeposit = msg.value;
        escrowDetails.disputeID = escrowDetails.arbitrator.createDispute{
            value: msg.value
        }(numberOfRulingOptions, "");
        escrowDetails.status = EscrowStatus.Disputed;
        disputeIDtoRelationshipID[escrowDetails.disputeID] = _relationshipID;
        emit Dispute(
            escrowDetails.arbitrator,
            escrowDetails.disputeID,
            _relationshipID,
            _relationshipID
        );
    }

    function rule(uint256 _disputeID, uint256 _ruling) public override {
        uint256 relationshipID = disputeIDtoRelationshipID[_disputeID];
        RelationshipEscrowDetails
            storage escrowDetails = relationshipEscrowDetails[relationshipID];

        Relationship relationship = Relationship(escrowDetails.relationshipAddress);

        if (msg.sender != address(escrowDetails.arbitrator)) {
            revert NotArbitrator();
        }
        if (escrowDetails.status != EscrowStatus.Disputed) {
            revert InvalidStatus();
        }
        if (_ruling > numberOfRulingOptions) {
            revert InvalidRuling(_ruling, numberOfRulingOptions);
        }
        escrowDetails.status = EscrowStatus.Resolved;

        if (_ruling == uint256(RulingOptions.PayerWins)) {
            daiToken.transfer(escrowDetails.payer, escrowDetails.value + escrowDetails.payerFeeDeposit);
       } else {
            daiToken.transfer(escrowDetails.payee, escrowDetails.value + escrowDetails.payeeFeeDeposit);
       }

       emit Ruling(escrowDetails.arbitrator, _disputeID, _ruling);

        relationship.notifyContract(
            uint256(RelationshipLibrary.ContractStatus.Approved)
        );
    }

    function submitEvidence(uint256 _relationshipID, string memory _evidence)
        public
    {
        RelationshipEscrowDetails
            storage escrowDetails = relationshipEscrowDetails[_relationshipID];

        if (escrowDetails.status == EscrowStatus.Resolved) {
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

        if (escrowDetails.status != EscrowStatus.Reclaimed) {
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
