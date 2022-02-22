// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interface/IRelationshipManager.sol";
import "../libraries/RelationshipLibrary.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TIP is ERC20 {
    address immutable manager;
    address immutable governor;
    mapping(address => uint256) private userToTreasuryFunds;

    modifier onlyOpportunityRelationshipManager() {
        require(msg.sender == manager);
        _;
    }

    modifier onlyOpportunityGovernor() {
        require(msg.sender == governor);
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _governor,
        address _manager
    ) ERC20(_name, _symbol) {
        manager = _manager;
        governor = _governor;
    }

    function awardTip(address _payee, uint256 _amount)
        external
        onlyOpportunityRelationshipManager
    {
        _mint(governor, _amount);
        userToTreasuryFunds[worker] = _amount;
    }

    function withdrawToPayee(address _payee, uint256 _amount)
        external
        onlyOpportunityGovernor
    {
        require(_amount < (userToTreasuryFunds[_payee] * 0.1));
        transfer(_payee, _amount);
    }
}
