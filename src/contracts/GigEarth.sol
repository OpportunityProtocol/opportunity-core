// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./libraries/RelationshipLibrary.sol";
import "./interface/IArbitrable.sol";
import "./interface/IEvidence.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GigEarth is IArbitrable, IEvidence {
    /**
     */
    event UserRegistered(address indexed universalAddress);

    /**
     */
    event UserAssignedTrueIdentification(address indexed universalAddress, address indexed userID);
    
    /**
     */
    event UserSummaryCreated(uint256 indexed registrationTimestamp, uint256 indexed index, address indexed universalAddress);

    /**
     * @dev To be emitted upon deploying a market
     */
    event MarketCreated(
        uint256 indexed index,
        address indexed creator,
        string indexed marketName
    );

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
    error InvalidRuling(uint256 _ruling, uint256 _numberOfChoices)

    struct Relationship {
        address valuePtr;
        uint256 relationshipID;
        address escrow;
        uint256 marketPtr;
        address employer;
        address worker;
        string taskMetadataPtr;
        ContractStatus contractStatus;
        ContractOwnership contractOwnership;
        ContractPayoutType contractPayoutType;
        uint256 wad;
        uint256 acceptanceTimestamp;
        uint256 resolutionTimestamp;
    }
    struct Market {
        string marketName;
        uint256 marketID;
        address relationshipManager;
        uint256[] relationships;
        address valuePtr;
        address[] participants;
    }

    struct RelationshipReviewBlacklistCheck {
        bool employerReviewed;
        bool workerReviewed;
    }
    struct EmployerDescription {
        mapping(uint256 => mapping(uint256 => bytes32)) marketsToRelationshipsToReviews;
    }

    /**
     * @notice Holds data for a user's worker behavior
     */
    struct WorkerDescription {
        mapping(uint256 => mapping(uint256 => bytes32)) marketsToRelationshipsToReviews;
    }

    struct UserSummary {
        uint256 userID;
        uint256 registrationTimestamp;
        address trueIdentification;
        bytes32[] reviews;
        uint256 primaryMarketID;
        EmployerDescription employerDescription;
        WorkerDescription workerDescription;
        bool isRegistered;
        uint256 lastPrimaryMarketRegistration;
    }

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

        enum Persona {
        Employer,
        Worker
    }

    /**
     * @dev Enum representing the states ownership for a relationship
     */
    enum ContractOwnership {
        Unclaimed,
        Pending,
        Claimed
    }

    /**
     * @dev Enum representing the states ownership for a relationship
     */
    enum ContractStatus {
        AwaitingWorker,
        AwaitingWorkerApproval,
        AwaitingResolution,
        Resolved,
        PendingDispute,
        Disputed
    }

    enum ContractPayoutType {
        Flat,
        Milestone,
        Deadline
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

    UserSummary[] public userSummaries;
    RelationshipLibrary.Market[] public markets;
    IArbitrator immutable arbitrator;

    address immutable deployer;

    uint256 numRelationships;
    uint256 constant numberOfRulingOptions = 2;
    uint256 public constant arbitrationFeeDepositPeriod = 1 minutes; // Timeframe is short on purpose to be able to test it quickly. Not for production use.
    uint8 public constant OPPORTUNITY_WITHDRAWAL_FEE = 10;

    mapping(address => UserSummary) public universalAddressToSummary;
    mapping(uint256 => RelationshipLibrary.Market) public marketIDToMarket;
    mapping(address => uint256) public universalAddressToUserID;
    mapping(uint256 => RelationshipLibrary.RelationshipReviewBlacklistCheck) public relationshipReviewBlacklist;
    mapping(uint256 => RelationshipLibrary.Relationship)
        public relationshipIDToRelationship;
    mapping(uint256 => uint256) public relationshipIDToMilestones;
    mapping(uint256 => uint256) public relationshipIDToCurrentMilestoneIndex;
    mapping(uint256 => uint256) public relationshipIDToDeadline;
    mapping(uint256 => uint256) public disputeIDtoRelationshipID;
    mapping(uint256 => RelationshipEscrowDetails) public relationshipIDToEscrowDetails;

    constructor(address _arbitrator) {
        arbitrator = IArbitrator(_arbitrator);
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
    function resolveTraditional(uint256 _relationshipID) external override {
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

    function resolveBounty(uint256 _relationshipID, address _worker) external {}

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

    // User Functions
    /**
    */
    function register() external returns(uint256) {
        if (isRegisteredUser(msg.sender)) {
            revert();
        }

        universalAddressToSummary[msg.sender] = _createUserSummary(msg.sender);
        userSummaries.push(universalAddressToSummary[msg.sender]);

        _assignTrueUserIdentification(msg.sender, universalAddressToSummary[msg.sender].userID);
        emit UserRegistered(msg.sender);
        
        return userSummaries.length - 1;
    }

    /**
    */
    function submitReview(
        address _relationshipManager,
        uint256 _relationshipID, 
        bytes32 _reviewHash
    ) external {
        IRelationshipManager manager = IRelationshipManager(_relationshipManager);
        RelationshipLibrary.Relationship memory relationship = manager.getRelationshipData(_relationshipID);

        require(relationship.contractStatus == RelationshipLibrary.ContractStatus.Resolved);
        require(block.timestamp < relationship.resolutionTimestamp + 30 days);
        
        UserSummary storage summary;
        if (relationship.worker() == msg.sender) {
            RelationshipLibrary.RelationshipReviewBlacklistCheck storage checklist = relationshipReviewBlacklist[_relationshipID];
            require(checklist.worker == 0);
            summary = universalAddressToSummary[relationship.worker()];
            checklist.worker = 1;
        } else if (relationship.employer() == msg.sender) {
            RelationshipLibrary.RelationshipReviewBlacklistCheck storage checklist = relationshipReviewBlacklist[_relationshipID];
            require(checklist.employer == 0);
            summary = universalAddressToSummary[relationship.employer()];
            checklist.employer = 1;
        } else revert();

        summary.reviews.push(_reviewHash);
    }

    /**
     */
    function _createUserSummary(address _universalAddress) internal returns(UserSummary memory) {
        UserSummary storage userSummary = UserSummary({
            userID: userSummaries.length + 1,
            registrationTimestamp: block.timestamp,
            trueIdentification: _universalAddress,
            isRegistered: true,
            reviews: new bytes32[]
        });

        emit UserSummaryCreated(userSummary.registrationTimestamp, userSummaries.length, _universalAddress);
        return userSummary;
    }

    function isRegisteredUser(address _userAddress) public view returns(bool) {
        return universalAddressToSummary[_userAddress].isRegistered;
    }

    /**
    */
    function _assignTrueUserIdentification(address _universalAddress, address _userID) internal {
        universalAddressToSummary[_universalAddress] = _userID;
        assert(universalAddressToUserID[_universalAddress] == _userID);
        emit UserAssignedTrueIdentification(_universalAddress, _userID);
    }

    // Market Functions
        /**
    */
    function createMarket(
        string memory _marketName,
        address _relationshipManager,
        address _valuePtr
    ) public returns (uint256) {
        uint256 marketID = markets.length + 1;

        RelationshipLibrary.Market memory newMarket = RelationshipLibrary.Market({
            marketName: _marketName,
            marketID: marketID,
            relationshipManager: _relationshipManager,
            relationships: new uint256[](0),
            valuePtr: _valuePtr,
            participants: [msg.sender]
        });

        markets.push(newMarket);
        marketIDToMarket[marketID] = newMarket;

        emit MarketCreated(
            marketID,
            msg.sender,
            _marketName
        );
        
        return markets.length;
    }

    /**
     * @param _marketID The id of the market to create the relationship
     * @param _escrow The address of the escrow for this relationship
     * @param _taskMetadataPtr The hash on IPFS for the relationship metadata
     * @param _deadline The deadline for the worker to complete the relationship
     */
    function createFlatRateRelationship(
        uint256 _marketID, 
        address _escrow, 
        string calldata _taskMetadataPtr, 
        uint256 _deadline
    ) external {
        RelationshipLibrary.Market storage market = marketIDToMarket[_marketID];
        uint256 relationshipID = market.relationships.length + 1;
        market.relationships.push(relationshipID);

        IRelationshipManager(market.relationshipManager).initializeContract(
            relationshipID,
            _deadline,
            _escrow,
            market.valuePtr,
            msg.sender,
            _marketID,
            _taskMetadataPtr
        );
    }

    /**
     * @param _marketID The id of the market to create the relationship
     * @param _escrow The address of the escrow for this relationship
     * @param _taskMetadataPtr The hash on IPFS for the relationship metadata
     * @param _deadline The deadline for the worker to complete the relationship
     * @param _numMilestones The number of milestones in this relationship
     */
    function createMilestoneRelationship(
        uint256 _marketID, 
        address _escrow, 
        string calldata _taskMetadataPtr, 
        uint256 _deadline, 
        uint256 _numMilestones
    ) external {
        RelationshipLibrary.Market storage market = marketIDToMarket[_marketID];
        uint256 relationshipID = market.relationships.length + 1;
        market.relationships.push(relationshipID);


        IRelationshipManager(market.relationshipManager).initializeContract(
            relationshipID,
            _deadline,
            _escrow,
            market.valuePtr,
            msg.sender,
            _marketID,
            _taskMetadataPtr,
            _numMilestones
        );
    }

    // Getters
    function getUserCount() public view returns(uint) {
        return userSummaries.length;
    }

    function getMarketParticipants(uint256 _marketID) public view returns(uint) {

    }

    function getMarketParticipantsCount(uint256 _marketID) public view returns(uint) {
        
    }

    /**
     * What value will this return and in what relation will it be to the normalized value?
     */
    function getLocalPeerScore(address _observer, address _observed) public view returns(uint) {
        UserSummary storage observer = universalAddressToSummary[_observer];
        return observer.peerScores[_observed];
    }

    function getMarketPeerScore(address _observed, uint256 _marketID) public view returns(uint) {
        
    }

    /**
    */
    function getTrueIdentification(address _user) public view returns(uint) {
        return universalAddressToSummary[_user].userID;
    }


}