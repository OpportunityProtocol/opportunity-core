// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./UserSummaryFactory.sol";

contract UserRegistration {

    // Mapping of universal address to summary contract address
    mapping(address => address) private _trueIdentifcations;

    event UserRegistered(address indexed universalAddress);
    event UserAssignedTrueIdentification(address indexed universalAddress, address indexed userSummaryContractAddress);

    UserSummaryFactory userSummaryFactory;

    constructor(address userSummaryFactoryAddress) {
        userSummaryFactory = UserSummaryFactory(userSummaryFactoryAddress);
    }

    function registerNewUser() external returns(address) {
        require(_trueIdentifcations[msg.sender] == address(0), "This user is already registered.");

        address userSummaryContractAddress = userSummaryFactory.createUserSummary(msg.sender);

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