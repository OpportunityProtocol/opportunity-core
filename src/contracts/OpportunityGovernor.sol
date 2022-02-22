// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./libraries/RelationshipLibrary.sol";
import "./interface/IRelationshipManager.sol";

contract OpportunityGovernor {
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

    UserLibrary.UserSummary[] public userSummaries;
    mapping(address => UserLibrary.UserSummary) public universalAddressToSummary;

    RelationshipLibrary.Market[] public markets;

    mapping(uint256 => RelationshipLibrary.Market) public marketIDToMarket;
    mapping(address => uint256) public universalAddressToUserID;
    
    // User Functions
    /**
    */
    function register() external returns(uint256) {
        if (isRegisteredUser(msg.sender)) revert()

        universalAddressToSummary[msg.sender] = _createUserSummary(msg.sender);
        userSummaries.push(userSummary);

        _assignTrueUserIdentification(msg.sender, universalAddressToSummary[msg.sender].userID);
        emit UserRegistered(msg.sender);
        
        return userSummaries.length - 1;
    }

    /**
    */
    function submitReview(
        address _relationshipManager,
        uint256  _relationshipID, 
        bytes32 _reviewHash
    ) external {
        IRelationshipManager manager = IRelationshipManager(_relationshipManager);
        RelationshipLibrary.Relationship memory relationship = manager.getRelationshipData(_relationshipID);

        require(universalAddressToSummary[msg.sender].isRegistered == true);
        require(relationship.resolutionTimestamp >= block.timestamp);
        require(block.timestamp < relationship.resolutionTimestamp + 30 days);
        
        UserLibrary.UserSummary storage summary;
        if (relationship.employer() == msg.sender) {
            summary = universalAddressToSummary[relationship.worker()];
        } else if (relationship.worker() == msg.sender) {
             summary = universalAddressToSummary[relationship.employer()];
        } else revert()

        summary.reviews.push(_reviewHash);
    }

    /**
     */
    function _createUserSummary(address _universalAddress) internal returns(UserLibrary.UserSummary memory) {
        UserLibrary.UserSummary userSummary = UserLibrary.UserSummary({
            userID: userSummaries.length + 1,
            registrationTimestamp: block.timestamp,
            trueIdentification: _universalAddress,
            isRegistered: true,
            reviews: new bytes32[]
        });

        emit UserSummaryCreated(userSummary.registrationTimestamp, userSummaries.length, _universalAddress);
        return userSummary;
    }

    function isRegisteredUser(address _userAddress) public constant view returns(bool isIndeed) {
        return universalAddressToSummary[_userAddress].isRegistered;
    }

    /**
    */
    function _assignTrueUserIdentification(address _universalAddress, address _userID) internal {
        universalToUserSummary[_universalAddress] = _userID;
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
            valuePtr: _valuePtr
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
    function getUserCount() public constant view returns(uint) {
        return userSummaries.length;
    }

    /**
    */
    function getTrueIdentification(address _user) public constant view {
        return universalAddressToUserID[_user];
    }
}