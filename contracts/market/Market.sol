// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../libraries/Evaluation.sol";
import "../exchange/WorkRelationship.sol";
import "../libraries/MarketLib.sol";

contract Market {
    event MarketPaused(
        address indexed marketAddress,
        string indexed marketName
    );
    event MarketResumed(
        address indexed marketAddress,
        string indexed marketName
    );
    event WorkRelationshipCreated(
        address indexed owner,
        address indexed relationship,
        address indexed marketAddress
    );
    event WorkRelationshipEnded(
        address indexed owner,
        address indexed relationship
    );

    string public _marketName;
    MarketLib.MarketType public _marketType;
    uint256 public _requiredReputation;
    uint256 public _requiredIndustryWeight;
    MarketLib.MarketStatus public _marketStatus;

    WorkRelationship[] _createdJobs;

    mapping(address => address) public relationshipsToOwner;

    constructor(string memory marketName, MarketLib.MarketType marketType) {
        _marketName = marketName;
        _marketType = marketType;
        // _requiredReputation = requiredReputation;
        // _requiredIndustryWeight = requiredIndustryWeight;
    }

    /**
     * Creates a user summary contract for each user based on their civic ID.
     */
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
        emit WorkRelationshipCreated(
            owner,
            address(createdJob),
            address(this)
        );
    }

    /**
     *
     */
    function getNumJobs() public view returns (uint256) {
        return _createdJobs.length;
    }

    function getWorkRelationships() external view returns (WorkRelationship[] memory) {
        return _createdJobs;
    }

    function destroyMarket() internal {
        //selfdestruct();
    }
}
