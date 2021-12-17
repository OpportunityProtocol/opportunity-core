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
    event MarketDispute(
        address indexed _employer,
        address indexed _worker,
        address indexed _relationship,
        address _dispute,
        address _market
    );

    string public _marketName;
    MarketLib.MarketType public _marketType;

    WorkRelationship[] _createdJobs;
    address[] observedDisputes;

    mapping(address => address) public relationshipsToOwner;

     modifier onlyFromRelationshipCaller(address _relationship) {
        require(msg.sender != address(0), "The relationship caller must not be a null address");
        WorkRelationship relationship = WorkRelationship(_relationship);

        //require relationship to be currently disputed (4) or approved (5)
        require(relationship.contractStatus() == Relationship.ContractStatus.Disputed);
        _;
    }

    constructor(string memory marketName, MarketLib.MarketType marketType) {
        _marketName = marketName;
        _marketType = marketType;
    }

    function createJob(
        address taskOwner,
        Evaluation.ContractType _contractType, 
        string memory taskMetadataPointer,
        address _daiTokenAddress
    ) external {
        address owner = taskOwner; //refactor to msg.sender
        require(owner != address(0), "Invalid task owner.");
        
        WorkRelationship createdJob =
            new WorkRelationship(taskOwner, _contractType, taskMetadataPointer, _daiTokenAddress);
        _createdJobs.push(createdJob);

        relationshipsToOwner[owner] = address(createdJob);

        emit WorkRelationshipCreated(
            owner,
            address(createdJob),
            address(this)
        );

        emit NewMarketParticipant(owner);
    }

    function observeRelationshipDispute(_employer, _worker, _dispute) onlyFromRelationshipCaller(msg.sender) external {
        observedDisputes.push(_dispute);
        emit MarketDispute(_employer, _worker, msg.sender, _dispute, address(this));
    }

    function getNumJobs() public view returns (uint256) {
        return _createdJobs.length;
    }

    function getWorkRelationships() external view returns (WorkRelationship[] memory) {
        return _createdJobs;
    }
}
