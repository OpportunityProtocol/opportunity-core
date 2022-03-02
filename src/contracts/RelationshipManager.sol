// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./interface/IRelationshipManager.sol";
import "./libraries/RelationshipLibrary.sol";
import "./interface/IArbitrable.sol";
import "./interface/IEvidence.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/**
 * @title RelationshipManager
 * @author Elijah Hampton
 */
contract RelationshipManager is IRelationshipManager, IArbitrable, IEvidence {
    /**
     * @dev To be emitted upon employer and worker entering contract.
     */
    event EnteredContract();

    /**
     * @dev To be emitted upon relationship status update
     */
    event ContractStatusUpdate();

    /**
     * @dev To be emitted upon relationship ownership update
     */
    event ContractOwnershipUpdate();

    error InvalidStatus();
    error ReleasedTooEarly();
    error NotPayer();
    error NotArbitrator();
    error ThirdPartyNotAllowed();
    error PayeeDepositStillPending();
    error ReclaimedTooLate();
    error InsufficientPayment(uint256 _available, uint256 _required);
    error InvalidRuling(uint256 _ruling, uint256 _numberOfChoices);

    uint256 numRelationships;
    uint256 constant numberOfRulingOptions = 2;
    uint256 public constant arbitrationFeeDepositPeriod = 1 minutes; // Timeframe is short on purpose to be able to test it quickly. Not for production use.

    address constant governor;

    IArbitrator immutable arbitrator;
    address immutable deployer;
    uint8 public constant OPPORTUNITY_WITHDRAWAL_FEE = 10;

    mapping(uint256 => RelationshipLibrary.Relationship)
        public relationshipIDToRelationship;
    mapping(uint256 => uint256) public relationshipIDToMilestones;
    mapping(uint256 => uint256) public relationshipIDToCurrentMilestoneIndex;
    mapping(uint256 => uint256) public relationshipIDToDeadline;
    mapping(uint256 => uint256) public disputeIDtoRelationshipID;
    mapping(uint256 => RelationshipEscrowDetails) public relationshipIDToEscrowDetails;

    enum RulingOptions {
        PayerWins,
        PayeeWins
    }

    enum EscrowStatus {
        Initial,
        Reclaimed,
        Disputed,
        Resolved
    }

    struct RelationshipEscrowDetails {
        EscrowStatus status;
        uint256 valuePtr;
        uint256 disputeID;
        uint256 createdAt;
        uint256 reclaimedAt;
        uint256 payerFeeDeposit;
        uint256 payeeFeeDeposit;
        uint256 arbitrationFeeDepositPeriod;
    }

    modifier onlyGovernor() {
        _;
    }

    constructor(address _arbitrator, address _governor, address) {
        arbitrator = IArbitrator(_arbitrator);
        _initialize(_governor);
    }

    /**
     * @notice Initializes the contract with the address to the governor contract.
     * @param _governor The address of the governor smart contract
     */
    function _initialize(address _governor) internal {
        governor = _governor;
    }

    /**
     * @inheritdoc IRelationshipManager
     */
    function initializeContract(uint256 _relationshipID, uint256 _deadline, address _escrow, address _valuePtr, address _employer, uint256 _marketID, string calldata _taskMetadataPtr) external override onlyGovernor {
        relationshipIDToRelationship[_relationshipID] = 
            RelationshipLibrary.Relationship({
                valuePtr: _valuePtr,
                relationshipID: _relationshipID,
                escrow: _escrow,
                marketPtr: _marketID,
                employer: _employer,
                worker: address(0),
                taskMetadataPtr: _taskMetadataPtr,
                contractStatus: RelationshipLibrary
                    .ContractStatus
                    .AwaitingWorker,
                contractOwnership: RelationshipLibrary
                    .ContractOwnership
                    .Unclaimed,
                contractPayoutType: RelationshipLibrary.ContractPayoutType.Flat,
                wad: 0,
                acceptanceTimestamp: 0,
                resolutionTimestamp: 0
            });

        relationshipIDToRelationship[
            _relationshipID
        ] = relationshipIDToRelationship[_relationshipID];

        if (_deadline != 0) {
            relationshipIDToDeadline[_relationshipID] = _deadline;
        }
        numRelationships++;
    }

    /**
     * @inheritdoc IRelationshipManager
     */
    function initializeContract(uint256 _relationshipID, uint256 _deadline, address _escrow, address _valuePtr, address _employer, uint256 _marketID, string calldata _taskMetadataPtr, uint256 _numMilestones) external override onlyGovernor {
        relationshipIDToRelationship[_relationshipID] = 
            RelationshipLibrary.Relationship({
                valuePtr: _valuePtr,
                relationshipID: _relationshipID,
                escrow: _escrow,
                marketPtr: _marketID,
                employer: _employer,
                worker: address(0),
                taskMetadataPtr: _taskMetadataPtr,
                contractStatus: RelationshipLibrary
                    .ContractStatus
                    .AwaitingWorker,
                contractOwnership: RelationshipLibrary
                    .ContractOwnership
                    .Unclaimed,
                contractPayoutType: RelationshipLibrary.ContractPayoutType.Flat,
                wad: 0,
                acceptanceTimestamp: 0,
                resolutionTimestamp: 0
            });

        relationshipIDToMilestones[_relationshipID] = _numMilestones;
        if (_deadline != 0) {
            relationshipIDToDeadline[_relationshipID] = _deadline;
        }
        numRelationships++;
    }

    /**
     * @inheritdoc IRelationshipManager
     */
    function grantProposalRequest(uint256 _relationshipID, address _newWorker, address _valuePtr,uint256 _wad, string memory _extraData) external override {
        RelationshipLibrary.Relationship storage relationship = relationshipIDToRelationship[_relationshipID];

        require(msg.sender == relationship.employer, "Only the employer of this relationship can grant the proposal.");
        require(_newWorker != address(0), "You must grant this proposal to a valid worker.");
        require(relationship.worker == address(0), "This job is already being worked.");
        require(_valuePtr != address(0), "You must enter a valid address for the value pointer.");
        require(_wad != uint256(0),"The payout amount must be greater than 0.");
        require(relationship.contractOwnership == RelationshipLibrary.ContractOwnership.Unclaimed,"This relationship must not already be claimed.");

        relationship.wad = _wad;
        relationship.valuePtr = _valuePtr;
        relationship.worker = _newWorker;
        relationship.acceptanceTimestamp = block.timestamp;

        relationship.contractOwnership = RelationshipLibrary.ContractOwnership.Pending;
        relationship.contractStatus = RelationshipLibrary.ContractStatus.AwaitingWorkerApproval;

        emit ContractStatusUpdate();
        emit ContractOwnershipUpdate();
    }

    /**
     * @inheritdoc IRelationshipManager
     */
    function work(uint256 _relationshipID, string memory _extraData) external override {
        RelationshipLibrary.Relationship storage relationship = relationshipIDToRelationship[_relationshipID];

        require(msg.sender == relationship.worker);
        require(relationship.contractOwnership ==RelationshipLibrary.ContractOwnership.Pending);
        require(relationship.contractStatus ==RelationshipLibrary.ContractStatus.AwaitingWorkerApproval);

        _initializeEscrowFundsAndTransfer(_relationshipID);

        relationship.contractOwnership = RelationshipLibrary.ContractOwnership.Claimed;
        relationship.contractStatus = RelationshipLibrary.ContractStatus.AwaitingResolution;
        relationship.acceptanceTimestamp = block.timestamp;

        emit EnteredContract();
        emit ContractStatusUpdate();
        emit ContractOwnershipUpdate();
    }

    /**
     * @inheritdoc IRelationshipManager
     */
    function releaseJob(uint256 _relationshipID) external override {
        RelationshipLibrary.Relationship storage relationship = relationshipIDToRelationship[_relationshipID];
        require(relationship.contractOwnership == RelationshipLibrary.ContractOwnership.Claimed);

        relationship.worker = address(0);
        relationship.acceptanceTimestamp = 0;
        relationship.wad = 0;
        relationship.contractStatus = RelationshipLibrary.ContractStatus.AwaitingWorker;
        relationship.contractOwnership = RelationshipLibrary.ContractOwnership.Unclaimed;

        _surrenderFunds(_relationshipID);

        emit ContractStatusUpdate();
        emit ContractOwnershipUpdate();
    }

    /**
     * @inheritdoc IRelationshipManager
     */
    function updateTaskMetadataPointer(uint256 _relationshipID, string calldata _newTaskPointerHash) external override {
        RelationshipLibrary.Relationship storage relationship = relationshipIDToRelationship[_relationshipID];

        require(msg.sender == relationship.employer);
        require(relationship.contractOwnership == RelationshipLibrary.ContractOwnership.Unclaimed);

        relationship.taskMetadataPtr = _newTaskPointerHash;
    }

    /**
     * @inheritdoc IRelationshipManager
     */
    function resolve(uint256 _relationshipID) external override {
        RelationshipLibrary.Relationship storage relationship = relationshipIDToRelationship[_relationshipID];

        require(msg.sender == relationship.employer);
        require(relationship.worker != address(0));
        require(relationship.wad != uint256(0));
        require(relationship.contractStatus == RelationshipLibrary.ContractStatus.AwaitingResolution);

        if (relationship.contractPayoutType == RelationshipLibrary.ContractPayoutType.Flat) {
            _resolveContractAndRewardWorker(_relationshipID);
        } else {
            if (relationshipIDToCurrentMilestoneIndex[_relationshipID] == relationshipIDToMilestones[_relationshipID] - 1) {
                _resolveContractAndRewardWorker(_relationshipID);
            } else {
                relationshipIDToCurrentMilestoneIndex[_relationshipID]++;
            }
        }
        
        emit ContractStatusUpdate();
    }

    /**
     * @notice Sets the contract status to resolved and releases the funds to the appropriate user.
     */
    function _resolveContractAndRewardWorker(uint256 _relationshipID) internal {
        RelationshipLibrary.Relationship storage relationship = relationshipIDToRelationship[_relationshipID];
         
        uint256 resolutionReward = relationship.wad / OPPORTUNITY_WITHDRAWAL_FEE;
         _releaseFunds(relationship.wad, _relationshipID);

        relationship.contractStatus = RelationshipLibrary.ContractStatus.Resolved;
    }

    /**
     * @inheritdoc IRelationshipManager
     */
    function getRelationshipData(uint256 _relationshipID) external override returns (RelationshipLibrary.Relationship memory)
    {
        return relationshipIDToRelationship[_relationshipID];
    }

    /// Non Interface Functionality ///

    /// Dispute Related Functions ///
    
    /**
     * @notice A call to this function initiates the arbitration pay period for the worker of the relationship.
     * @dev The employer must call this function a second time to claim the funds from this contract if worker does not with to enter arbitration.
     * @param _relationshipID The id of the relationship to begin a disputed state 
     */
    function disputeRelationship(uint256 _relationshipID) external payable {
        RelationshipManager rManager = RelationshipManager(msg.sender);
        RelationshipLibrary.Relationship memory relationship = rManager.getRelationshipData(_relationshipID);

        RelationshipEscrowDetails storage escrowDetails = relationshipIDToEscrowDetails[_relationshipID];

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

            escrowDetails.valuePtr.transfer(escrowDetails.payee,escrowDetails.value + escrowDetails.payerFeeDeposit);
            escrowDetails.value = 0;
            escrowDetails.status = EscrowStatus.Resolved;

            relationship[_relationshipID].contractStatus = RelationshipLibrary.ContractStatus.Resolved;
        } else {
            uint256 requiredAmount = escrowDetails.arbitrator.arbitrationCost("");
            if (msg.value < requiredAmount) {
                revert InsufficientPayment(msg.value, requiredAmount);
            }

            escrowDetails.payerFeeDeposit = msg.value;
            escrowDetails.reclaimedAt = block.timestamp;
            escrowDetails.status = EscrowStatus.Reclaimed;

            relationship[_relationshipID].contractStatus = RelationshipLibrary.ContractStatus.Disputed;
        }
    }

    /**
     * @notice Allows the worker to depo
     */
    function depositArbitrationFeeForPayee(uint256 _relationshipID)
        external
        payable
    {
        RelationshipEscrowDetails storage escrowDetails = relationshipIDToEscrowDetails[_relationshipID];

        if (escrowDetails.status != EscrowStatus.Reclaimed) {
            revert InvalidStatus();
        }

        escrowDetails.payeeFeeDeposit = msg.value;
        escrowDetails.disputeID = escrowDetails.arbitrator.createDispute{value: msg.value}(numberOfRulingOptions, "");
        escrowDetails.status = EscrowStatus.Disputed;
        disputeIDtoRelationshipID[escrowDetails.disputeID] = _relationshipID;
        emit Dispute(
            escrowDetails.arbitrator,
            escrowDetails.disputeID,
            _relationshipID,
            _relationshipID
        );
    }

    /**
     *
     */
    function rule(uint256 _disputeID, uint256 _ruling) public override {
        uint256 _relationshipID = disputeIDtoRelationshipID[_disputeID];
        RelationshipEscrowDetails
            storage escrowDetails = relationshipIDToEscrowDetails[_relationshipID];

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

            relationship[_relationshipID].contractStatus = RelationshipLibrary.ContractStatus.Resolved;
    }

    /**
     * @notice Allows either party to submit evidence for the ongoing dispute.
     * @dev The escrow status of the smart contract must be in the disputed state.
     * @param _relationshipID The id of the relationship to submit evidence.
     * @param _evidence A link to some evidence provided for this relationship.
     */
    function submitEvidence(uint256 _relationshipID, string memory _evidence)
        public
    {
        RelationshipEscrowDetails
            storage escrowDetails = relationshipIDToEscrowDetails[_relationshipID];

        if (escrowDetails.status != EscrowStatus.Disputed) {
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

    /**
     * @notice Returns the remaining time to deposit the arbitration fee.
     * @param _relationshipID The id of the relationship to return the remaining time.
     */
    function remainingTimeToDepositArbitrationFee(uint256 _relationshipID) external view returns (uint256) {
        RelationshipEscrowDetails storage escrowDetails = relationshipIDToEscrowDetails[_relationshipID];

        if (escrowDetails.status != EscrowStatus.Reclaimed) {
            revert InvalidStatus();
        }

        return (block.timestamp - escrowDetails.reclaimedAt) > escrowDetails.arbitrationFeeDepositPeriod ? 0 : (escrowDetails.reclaimedAt + escrowDetails.arbitrationFeeDepositPeriod - block.timestamp);
    }

    /// Escrow Related Functions ///

    /**
     * @notice Initializes the funds into the escrow and records the details of the escrow into a struct.
     * @param _relationshipID The ID of the relationship to initialize escrow details
     */
    function _initializeEscrowFundsAndTransfer(uint256 _relationshipID) internal {
        RelationshipManager rManager = RelationshipManager(msg.sender);
        RelationshipLibrary.Relationship memory relationship = rManager.getRelationshipData(_relationshipID);
 
        relationshipIDToEscrowDetails[_relationshipID] = RelationshipEscrowDetails({
            arbitrator: arbitrator,
            status: EscrowStatus.Initial,
            valuePtr: relationship.wad,
            disputeID: _relationshipID,
            createdAt: block.timestamp,
            reclaimedAt: 0,
            payerFeeDeposit: 0,
            payeeFeeDeposit: 0,
            arbitrationFeeDepositPeriod: arbitrationFeeDepositPeriod
        });

        IERC20(relationship.valuePtr).transferFrom(relationship.employer, address(this), relationship.wad);
    }

    /**
     * @notice Releases the escrow funds back to the employer.
     * @param _relationshipID The ID of the relationship to surrender the funds.
     */
    function _surrenderFunds(uint256 _relationshipID) internal {
        RelationshipManager rManager = RelationshipManager(msg.sender);
        RelationshipLibrary.Relationship memory relationship = rManager.getRelationshipData(_relationshipID);
        RelationshipEscrowDetails storage escrowDetails = relationshipIDToEscrowDetails[_relationshipID];

        require(msg.sender == escrowDetails.relationshipManagerAddress);

        IERC20(relationship.valuePtr).transfer(escrowDetails.payer, escrowDetails.value);
    }

    /**
     * @notice Releases the escrow funds to the worker.
     * @param _amount The amount to release to the worker
     * @param _relationshipID The ID of the relationship to transfer funds
     */
    function _releaseFunds(uint256 _amount, uint256 _relationshipID) internal {
        RelationshipManager rManager = RelationshipManager(msg.sender);
        RelationshipLibrary.Relationship memory  relationship = rManager.getRelationshipData(_relationshipID);
        RelationshipEscrowDetails storage escrowDetails = relationshipIDToEscrowDetails[_relationshipID];
            
        require(msg.sender == escrowDetails.relationshipManagerAddress);


        if (relationship.contractStatus != RelationshipLibrary.ContractStatus.Resolved) {
            revert InvalidStatus();
        }

        escrowDetails.status = EscrowStatus.Resolved;

        uint256 fee = _amount * OPPORTUNITY_WITHDRAWAL_FEE;
        uint256 payout = _amount - fee;
        IERC20(relationship.valuePtr).transfer(escrowDetails.payee, payout);
        escrowDetails.value = 0;
    }
}
