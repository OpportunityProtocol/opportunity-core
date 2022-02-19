// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./UserSummaryFactory.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract UserRegistration is UserSummaryFactory {
    event UserRegistered(address indexed universalAddress);
    event UserAssignedTrueIdentification(address indexed universalAddress, address indexed userSummaryContractAddress);

    mapping(address => address) public universalToUserSummary;

    address immutable governor;

    constructor(address _governor) {
        governor = _governor;
    }

    function register() external returns(address) {
        require(universalToUserSummary[msg.sender] == address(0), "A user has already been registered with this address.");

        address userSummaryContractAddress = _createUserSummary(msg.sender, governor);

        _assignTrueUserIdentification(msg.sender, userSummaryContractAddress);
        emit UserRegistered(msg.sender);

        return userSummaryContractAddress;
    }

    function _assignTrueUserIdentification(address _universalAddress, address _summaryContractAddress) internal {
        universalToUserSummary[_universalAddress] = _summaryContractAddress;
        assert(universalToUserSummary[_universalAddress] == _summaryContractAddress);
        emit UserAssignedTrueIdentification(_universalAddress, _summaryContractAddress);
    }
}