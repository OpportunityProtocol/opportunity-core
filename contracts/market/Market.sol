// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../libraries/Evaluation.sol";
import "../exchange/WorkRelationship.sol";
import "../libraries/MarketLib.sol";

contract Market {
    event WorkRelationshipCreated(
        address indexed owner,
        address indexed relationship,
        address indexed marketAddress
    );
    event WorkRelationshipEnded(
        address indexed owner,
        address indexed relationship
    );

    event NewMarketParticipant(address indexed participant);

    string public marketName;
    MarketLib.MarketType public marketType;

    address[] public createdJobs;

    mapping(address => address[]) public relationshipsToOwner;


    constructor(string memory _marketName, MarketLib.MarketType _marketType) {
        marketName = _marketName;
        marketType = _marketType;
    }

    function createJob(
        address _registrar,
        Evaluation.ContractType _contractType, 
        string memory taskMetadataPointer,
        address _daiTokenAddress
    ) external {
        require(msg.sender != address(0), "Invalid task owner.");
        address owner = msg.sender;
        
        WorkRelationship createdJob =
            new WorkRelationship(_registrar, _contractType, taskMetadataPointer, _daiTokenAddress);

        createdJobs.push(address(createdJob));
        relationshipsToOwner[owner].push(address(createdJob));

        emit WorkRelationshipCreated(
            owner,
            address(createdJob),
            address(this)
        );

        emit NewMarketParticipant(owner);
    }

    function getNumRelationshipsCreated() public view returns (uint256) {
        return createdJobs.length;
    }

    function getWorkRelationships() external view returns (address[] memory) {
        return createdJobs;
    }

    function getWorkRelationshipsByOwner(address _owner) external view returns (address[] memory) {
        return relationshipsToOwner[_owner];
    }
}
