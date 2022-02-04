// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../exchange/interface/Relationship.sol";
import "../exchange/FlatRateRelationship.sol";
import "../libraries/MarketLib.sol";

contract Market {
    event RelationshipCreated(
        address indexed owner,
        address indexed relationship,
        address indexed marketAddress
    );

    event NewMarketParticipant(address indexed participant);

    string public marketName;
    address[] public marketRelationships;
    mapping(address => address[]) public relationshipsToOwner;
    MarketLib.MarketType public marketType;

    constructor(string memory _marketName) {
        marketName = _marketName;
    }

    function recordJob(address relationship, address employer) internal {
        marketRelationships.push(address(createdJob));
        relationshipsToOwner[employer].push(relationship);

        emit RelationshipCreated(
            employer,
            relationship,
            address(this)
        );

        emit NewMarketParticipant(msg.sender);
    }

    function createFlatRateJob(
        address _daiTokenAddress,
        address _relationshipEscrow,
        string memory _taskMetadataPointer,
    ) external {
        require(msg.sender != address(0), "The relationship employer cannot be set to a null address");
        
        Relationship createdJob = new FlatRateRelationship(
            marketRelationships.length, 
            _registrar, 
            _daiTokenAddress,
            _relationshipEscrow,
            _taskMetadataPointer
        );

        this.recordJob(address(createdJob), msg.sender);
    }

    function getNumRelationshipsCreated() public view returns (uint256) {
        return marketRelationships.length;
    }

    function getRelationships() external view returns (address[] memory) {
        return marketRelationships;
    }

    function getRelationshipsByOwner(address _owner) external view returns (address[] memory) {
        return relationshipsToOwner[_owner];
    }
}
