// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../libraries/Evaluation.sol";
import "../exchange/WorkRelationship.sol";
import "../libraries/MarketLib.sol";

/**
 * Market
 * Deploy a new market to the network based on the industry.  Ride sharing, web development, etc..
 */
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
    address[] public createdJobs;
    mapping(address => address[]) public relationshipsToOwner;
    MarketLib.MarketType public marketType;

    constructor(string memory _marketName, MarketLib.MarketType _marketType) {
        marketName = _marketName;
        marketType = _marketType;
    }

    /**
     * createJob
     * Registers a new job in this market
     * @param _registrar Address of the user registration contract
     * @param _contractType The contract type you would like to deploy (normal, flash).. Only normal types are supported at this time
     * @param _taskMetadataPointer The pointer to the metadata of the job saved on IPFS
     * @param _daiTokenAddress Token address of DAI according to which network is being used
     */
    function createJob(
        address _registrar,
        Evaluation.ContractType _contractType, 
        string memory _taskMetadataPointer,
        address _daiTokenAddress
    ) external {
        require(msg.sender != address(0), "The owner of the job cannot be set to a null address");
        
        WorkRelationship createdJob =
            new WorkRelationship(_registrar, _contractType, _taskMetadataPointer, _daiTokenAddress);

        createdJobs.push(address(createdJob));
        relationshipsToOwner[msg.sender].push(address(createdJob));

        emit WorkRelationshipCreated(
            msg.sender,
            address(createdJob),
            address(this)
        );

        emit NewMarketParticipant(msg.sender);
    }

    /**
     * getNumRelationshipsCreated
     * @return Returns the number of jobs created in this market
     */
    function getNumRelationshipsCreated() public view returns (uint256) {
        return createdJobs.length;
    }

    /**
     * getWorkRelationships
     * @return Returns the list of created jobs
     */
    function getWorkRelationships() external view returns (address[] memory) {
        return createdJobs;
    }

    /**
     * getWorkRelationshipsByOwner
     * @param _owner The owner of the desired list of relationships
     * @return Returns a mapping of relationships to owners
     */
    function getWorkRelationshipsByOwner(address _owner) external view returns (address[] memory) {
        return relationshipsToOwner[_owner];
    }
}
