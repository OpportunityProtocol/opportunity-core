// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./UserSummaryFactory.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract UserRegistration is UserSummaryFactory {
    // Mapping of universal address to summary contract address
    mapping(address => address) private _trueIdentifcations;

    event UserRegistered(address indexed universalAddress);
    event UserAssignedTrueIdentification(address indexed universalAddress, address indexed userSummaryContractAddress);

    function registerNewUser() external returns(address) {
        require(_trueIdentifcations[msg.sender] == address(0), "This user is already registered.");

        address userSummaryContractAddress = this.createUserSummary(msg.sender);

        assignTrueUserIdentification(msg.sender, userSummaryContractAddress);
        emit UserRegistered(msg.sender);

        return userSummaryContractAddress;
     }

    /**
     * assignTrueUserIdentification
     */
    function assignTrueUserIdentification(address universalAddress, address summaryContractAddress) internal {
        _trueIdentifcations[universalAddress] = summaryContractAddress;
        assert(_trueIdentifcations[universalAddress] == summaryContractAddress);
        emit UserAssignedTrueIdentification(universalAddress, summaryContractAddress);
    }

    function getTrueIdentification(address universalAddress) external view returns(address) {
        return _trueIdentifcations[universalAddress];
    }
}