// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./UserSummaryFactory.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


contract UserRegistration is UserSummaryFactory {
    event UserRegistered(address indexed universalAddress);
    event UserAssignedTrueIdentification(address indexed universalAddress, address indexed userSummaryContractAddress);

    mapping(address => address) public trueIdentifcations;

    function registerNewUser() external {
        require(trueIdentifcations[msg.sender] == address(0), "A user has already been registered with this address.");

        address userSummaryContractAddress = _createUserSummary(msg.sender);

        assignTrueUserIdentification(msg.sender, userSummaryContractAddress);
        emit UserRegistered(msg.sender);
     }

    function assignTrueUserIdentification(address _universalAddress, address _summaryContractAddress) internal {
        trueIdentifcations[_universalAddress] = _summaryContractAddress;
        assert(trueIdentifcations[_universalAddress] == _summaryContractAddress);
        emit UserAssignedTrueIdentification(_universalAddress, _summaryContractAddress);
    }

    function getTrueIdentification(address universalAddress) external view returns(address) {
        return trueIdentifcations[universalAddress];
    }
}