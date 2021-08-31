// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./UserSummaryFactory.sol";
import "../control/Controllable.sol";

contract UserRegistration is Controllable {

    // Mapping of universal address to summary contract address
    mapping(address => address) private _trueIdentifcations;

    event UserRegistered(address indexed universalAddress);
    event UserAssignedTrueIdentification(address indexed universalAddress, address indexed userSummaryContractAddress);

    UserSummaryFactory userSummaryFactory;

    constructor(address userSummaryFactoryAddress) {
        userSummaryFactory = UserSummaryFactory(userSummaryFactoryAddress);
    }

    /**
     * registerNewUser
     * @param universalAddress Universal user address
     */
     function registerNewUser(address universalAddress) external returns(address) {
        require(_trueIdentifcations[universalAddress] == address(0), "This user is already registered.");

        address userSummaryContractAddress = userSummaryFactory.createUserSummary(universalAddress);

        assignTrueUserIdentification(universalAddress, userSummaryContractAddress);
        emit UserRegistered(universalAddress);

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