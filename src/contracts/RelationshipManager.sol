// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interface/IRelationshipManager.sol";
import "../libraries/RelationshipLibrary.sol";

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

    /**
     * @dev To be emitted upon external state update from escrow
     */
    event ExternalStatusNotification();

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
    uint256 public constant arbitrationFeeDepositPeriod = 3 minutes; // Timeframe is short on purpose to be able to test it quickly. Not for production use.

    address constant governor;
    address constant workerTreasury;

    IArbitrator immutable arbitrator;

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

    constructor(address _arbitrator) {
        arbitrator = IArbitrator(_arbitrator);
    }

    function initialize(address _governor, address _treasury) public onlyOwner {
        governor = _governor;
        treasury = _treasury;
    }

    /**
     * @inheritdoc IRelationshipManager
     */
    function initializeContract(
        uint256 _relationshipID,
        uint256 _deadline,
        address _escrow,
        address _valuePtr,
        address _employer,
        uint256 _marketID,
        string calldata _taskMetadataPtr
    ) external override onlyGovernor {
        relationshipIDToRelationship[_relationshipID] = RelationshipLibrary
            .Relationship({
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
    function initializeContract(
        uint256 _relationshipID,
        uint256 _deadline,
        address _escrow,
        address _valuePtr,
        address _employer,
        uint256 _marketID,
        string calldata _taskMetadataPtr,
        uint256 _numMilestones
    ) external override onlyGovernor {
        relationshipIDToRelationship[_relationshipID] = RelationshipLibrary
            .Relationship({
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
    function grantProposalRequest(
        uint256 _relationshipID,
        address _newWorker,
        address _valuePtr,
        uint256 _wad,
        string memory _extraData
    ) external override {
        RelationshipLibrary.Relationship
            storage relationship = relationshipIDToRelationship[
                _relationshipID
            ];

        require(
            msg.sender == relationship.employer,
            "Only the employer of this relationship can grant the proposal."
        );
        require(
            _newWorker != address(0),
            "You must grant this proposal to a valid worker."
        );
        require(
            relationship.worker == address(0),
            "This job is already being worked."
        );
        require(
            _valuePtr != address(0),
            "You must enter a valid address for the value pointer."
        );
        require(
            _wad != uint256(0),
            "The payout amount must be greater than 0."
        );
        require(
            relationship.contractOwnership ==
                RelationshipLibrary.ContractOwnership.Unclaimed,
            "This relationship must not already be claimed."
        );

        relationship.wad = _wad;
        relationship.valuePtr = _valuePtr;
        relationship.worker = _newWorker;
        relationship.acceptanceTimestamp = block.timestamp;

        relationship.contractOwnership = RelationshipLibrary
            .ContractOwnership
            .Pending;
        relationship.contractStatus = RelationshipLibrary
            .ContractStatus
            .AwaitingWorkerApproval;

        emit ContractStatusUpdate();
        emit ContractOwnershipUpdate();
    }

    /**
     * @inheritdoc IRelationshipManager
     */
    function work(uint256 _relationshipID, string memory _extraData) external override {
        RelationshipLibrary.Relationship
            storage relationship = relationshipIDToRelationship[
                _relationshipID
            ];

        require(msg.sender == relationship.worker);
        require(
            relationship.contractOwnership ==
                RelationshipLibrary.ContractOwnership.Pending
        );
        require(
            relationship.contractStatus ==
                RelationshipLibrary.ContractStatus.AwaitingWorkerApproval
        );

        _initializeEscrowFundsAndTransfer(_relationshipID);

        relationship.contractOwnership = RelationshipLibrary
            .ContractOwnership
            .Claimed;
        relationship.contractStatus = RelationshipLibrary
            .ContractStatus
            .AwaitingResolution;
        relationship.acceptanceTimestamp = block.timestamp;

        emit EnteredContract();
        emit ContractStatusUpdate();
        emit ContractOwnershipUpdate();
    }

    /**
     * @inheritdoc IRelationshipManager
     */
    function releaseJob(uint256 _relationshipID) external override {
        RelationshipLibrary.Relationship
            storage relationship = relationshipIDToRelationship[
                _relationshipID
            ];

        require(
            relationship.contractOwnership ==
                RelationshipLibrary.ContractOwnership.Claimed
        );

        relationship.worker = address(0);
        relationship.acceptanceTimestamp = 0;
        relationship.wad = 0;
        relationship.contractStatus = RelationshipLibrary
            .ContractStatus
            .AwaitingWorker;
        relationship.contractOwnership = RelationshipLibrary
            .ContractOwnership
            .Unclaimed;

        _surrenderFunds(_relationshipID);

        emit ContractStatusUpdate();
        emit ContractOwnershipUpdate();
    }

    /**
     * @inheritdoc IRelationshipManager
     */
    function updateTaskMetadataPointer(
        uint256 _relationshipID,
        string calldata _newTaskPointerHash
    ) external override {
        RelationshipLibrary.Relationship
            storage relationship = relationshipIDToRelationship[
                _relationshipID
            ];

        require(msg.sender == relationship.employer);
        require(
            relationship.contractOwnership ==
                RelationshipLibrary.ContractOwnership.Unclaimed
        );

        relationship.taskMetadataPtr = _newTaskPointerHash;
    }

    /**
     * @inheritdoc IRelationshipManager
     */
    function contractStatusNotification(
        uint256 _relationshipID,
        RelationshipLibrary.ContractStatus _status
    ) external override {
        RelationshipLibrary.Relationship
            storage relationship = relationshipIDToRelationship[
                _relationshipID
            ];

        require(msg.sender == address(relationship.escrow));

        relationship.contractStatus = _status;

        emit ExternalStatusNotification();
    }

    /**
     * @inheritdoc IRelationshipManager
     */
    function resolve(uint256 _relationshipID) external override {
        RelationshipLibrary.Relationship
            storage relationship = relationshipIDToRelationship[
                _relationshipID
            ];

        require(msg.sender == relationship.employer);
        require(relationship.worker != address(0));
        require(relationship.wad != uint256(0));
        require(
            relationship.contractStatus ==
                RelationshipLibrary.ContractStatus.AwaitingResolution
        );

        if (
            relationship.contractPayoutType ==
            RelationshipLibrary.ContractPayoutType.Flat
        ) {
            resolveContractAndRewardWorker()
        } else {
            if (relationshipIDToCurrentMilestoneIndex[_relationshipID] == relationshipIDToMilestones[_relationshipID] - 1) {
                resolveContractAndRewardWorker()
            } else {
                relationshipIDToCurrentMilestoneIndex[_relationshipID]++;
            }
        }
        
        emit ContractStatusUpdate();
    }

    function resolveContractAndRewardWorker() internal {
                                _releaseFunds(
                    relationship.wad,
                 _relationshipID
                );

                relationship.contractStatus = RelationshipLibrary
                .ContractStatus
                .Resolved;

                        uint256 tipReward = wad * 0.3;
        tipToken.awardTip(tipReward, worker);
    }

    /**
     * @inheritdoc IRelationshipManager
     */
    function getRelationshipData(uint256 _relationshipID)
        external override
        returns (RelationshipLibrary.Relationship memory)
    {
        return relationshipIDToRelationship[_relationshipID];
    }

    /// Non Interface Functionality ///

    /// Dispute Related Functions ///
    
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

            //tell governor of deragtory mark
            governor.grantDeragatoryMark();
        } else {
            IERC20(relationship.valuePtr).transfer(escrowDetails.payee, escrowDetails.value + escrowDetails.payeeFeeDeposit);
            
            //tell governor of deragatory mark
            governor.grantDeragatoryMark();
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

    /// Escrow Related Functions ///

        /**
     */
    function _initializeEscrowFundsAndTransfer(
        uint256 _relationshipID,
    ) internal {
        RelationshipManager rManager = RelationshipManager(msg.sender);
        RelationshipLibrary.Relationship memory relationship = rManager.getRelationshipData(_relationshipID);
 
        relationshipEscrowDetails[_relationshipID] = RelationshipEscrowDetails({
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
     */
    function _surrenderFunds(uint256 _relationshipID) internal {
        RelationshipManager rManager = RelationshipManager(msg.sender);
        RelationshipLibrary.Relationship memory relationship = rManager.getRelationshipData(_relationshipID);
        RelationshipEscrowDetails storage escrowDetails = relationshipEscrowDetails[_relationshipID];

        require(msg.sender == escrowDetails.relationshipManagerAddress);

        IERC20(relationship.valuePtr).transfer(escrowDetails.payer, escrowDetails.value);
    }

    /**
     */
    function _releaseFunds(uint256 _amount, uint256 _relationshipID) internal {
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
}
