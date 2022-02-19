pragma solidity 0.8.7;

import "../interface/IArbitrable.sol";
import "../interface/IEvidence.sol";
import "../relationship/RelationshipManager.sol";
import "../libraries/RelationshipLibrary.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title RelationshipEscrow
/// @author Elijah Hampton
/// @notice This contract can be used as a escrow for Opportunity Relationship managers.
contract RelationshipEscrow is IArbitrable, IEvidence, IEscrow {
    IArbitrator immutable arbitrator;
    IERC20 valueToken;
    
    constructor(address _arbitrator) {
        arbitrator = IArbitrator(_arbitrator);
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
        address relationshipManagerAddress;
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
        uint256 _relationshipID,
        string calldata _metaevidence
    ) external override {
        RelationshipManager rManager = RelationshipManager(msg.sender);
        RelationshipLibrary.Relationship memory relationship = rManager.getRelationshipData(_relationshipID);

        emit MetaEvidence(_relationshipID, _metaevidence);
 
        relationshipEscrowDetails[_relationshipID] = RelationshipEscrowDetails({
            payer: relationship.employer,
            payee: relationship.worker,
            arbitrator: arbitrator,
            status: EscrowStatus.Initial,
            relationshipManagerAddress: msg.sender,
            value: relationship.wad,
            disputeID: _relationshipID,
            createdAt: block.timestamp,
            reclaimedAt: 0,
            payerFeeDeposit: 0,
            payeeFeeDeposit: 0,
            arbitrationFeeDepositPeriod: arbitrationFeeDepositPeriod
        });

        IERC20(relationship.valuePtr).transferFrom(relationship.employer, address(this), relationship.wad);
    }

    function surrenderFunds(uint256 _relationshipID) external override {
        RelationshipManager rManager = RelationshipManager(msg.sender);
        RelationshipLibrary.Relationship memory relationship = rManager.getRelationshipData(_relationshipID);
        RelationshipEscrowDetails storage escrowDetails = relationshipEscrowDetails[_relationshipID];

        require(msg.sender == escrowDetails.relationshipManagerAddress);

        IERC20(relationship.valuePtr).transfer(escrowDetails.payer, escrowDetails.value);
    }

    function releaseFunds(uint256 _amount, uint256 _relationshipID) external override {
        RelationshipManager rManager = RelationshipManager(msg.sender);
        RelationshipLibrary.Relationship memory  relationship = rManager.getRelationshipData(_relationshipID);
        RelationshipEscrowDetails
            storage escrowDetails = relationshipEscrowDetails[_relationshipID];
            
        require(msg.sender == escrowDetails.relationshipManagerAddress);


        if (relationship.contractStatus != RelationshipLibrary.ContractStatus.Resolved) {
            revert InvalidStatus();
        }

        escrowDetails.status = EscrowStatus.Resolved;

        IERC20(relationship.valuePtr).transfer(escrowDetails.payee, _amount);
        escrowDetails.value = escrowDetails.value - _amount;
    }

    function disputeRelationship(uint256 _relationshipID) external payable {
        RelationshipManager rManager = RelationshipManager(msg.sender);
        RelationshipLibrary.Relationship memory relationship = rManager.getRelationshipData(_relationshipID);

        RelationshipEscrowDetails storage escrowDetails = relationshipEscrowDetails[_relationshipID];

        if (relationship.contractOwnership != RelationshipLibrary.ContractOwnership.Claimed) {
            revert InvalidStatus();
        }

        if (msg.sender != escrowDetails.payer) {
            revert NotPayer();
        }

        if (escrowDetails.status == EscrowStatus.Reclaimed) {
            if (
                block.timestamp - escrowDetails.reclaimedAt <=
                escrowDetails.arbitrationFeeDepositPeriod
            ) {
                revert PayeeDepositStillPending();
            }

            valueToken.transfer(
                escrowDetails.payee,
                escrowDetails.value + escrowDetails.payerFeeDeposit
            );
            escrowDetails.value = 0;
            escrowDetails.status = EscrowStatus.Resolved;

            rManager.contractStatusNotification(_relationshipID, RelationshipLibrary.ContractStatus.Resolved);
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
            rManager.contractStatusNotification(_relationshipID, RelationshipLibrary.ContractStatus.Disputed);
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
        uint256 _relationshipID = disputeIDtoRelationshipID[_disputeID];
        RelationshipEscrowDetails
            storage escrowDetails = relationshipEscrowDetails[_relationshipID];

        RelationshipManager rManager = RelationshipManager(escrowDetails.relationshipManagerAddress);
        RelationshipLibrary.Relationship memory relationship = rManager.getRelationshipData(_relationshipID);

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
            IERC20(relationship.valuePtr).transfer(escrowDetails.payer, escrowDetails.value + escrowDetails.payerFeeDeposit);
        } else {
            IERC20(relationship.valuePtr).transfer(escrowDetails.payee, escrowDetails.value + escrowDetails.payeeFeeDeposit);
        }

        emit Ruling(escrowDetails.arbitrator, _disputeID, _ruling);

        rManager.contractStatusNotification(_relationshipID, RelationshipLibrary.ContractStatus.Resolved);
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
