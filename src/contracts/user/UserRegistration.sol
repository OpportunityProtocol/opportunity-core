// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./UserSummaryFactory.sol";

contract UserRegistration { //FU SUV

    //maps a civic address to a universal generated address
    mapping(string => address) private _universalAddress;

    // Mapping of civic id to universal address existing status
    mapping(string => bool) private _hasUniversalAddress;

    // Mapping of universal address to summary contract address
    mapping(address => address) private _trueUserIdentifcation;

    event UserRegistered(string indexed civicID, address indexed universalAddress);

    constructor() {}

    /**
     * registerNewUser
     * Registers a new user to the platform based on their civicID.
     * @param civicID Hash returned from civic identity wallet
     * @param newUniversalAddress Universal user address
     */
     function registerNewUser(string memory civicID, address newUniversalAddress) external returns(bool) {
        bool hasAssignedUniversalAddressResult = assignUniversalAddress(civicID, newUniversalAddress);
        require(hasAssignedUniversalAddressResult == false);

        UserSummaryFactory factory = new UserSummaryFactory();
        address userSummaryContractAddress = factory.createUserSummary(civicID);

        assignTrueUserIdentification(newUniversalAddress, userSummaryContractAddress);
     }

    /**
     * assignTrueUserIdentification
     */
    function assignTrueUserIdentification(address universalAddress, address summaryContractAddress) internal returns(bool) {
        _trueUserIdentifcation[universalAddress] = summaryContractAddress;
    }

    /**
     * assignUniversalAddress
     * Maps a users civic id to the universal address for the platform.
     * @param civicID Hash returned from civic identity wallet
     * @param newUniversalAddress Universal user address
     */
    function assignUniversalAddress(string memory civicID, address newUniversalAddress) internal returns(bool) {
        //require this address not to already have a universal address
        require(_hasUniversalAddress[civicID] == false);
        //require there to not be a universal address at this index
        require(true == false);

        //assign the civic address to a new universal address
        _universalAddress[civicID] = newUniversalAddress; 
    }

    /**
     * hasUniversalAddress
     * Returns Checks to see if a user has a universal address or not.
     * @param civicID Hash returned from civic identity wallet
     * @return bool based on if a user has a universal address or not.
     */
    function hasUniversalAddress(string memory civicID) internal view returns(bool) {
        return _hasUniversalAddress[civicID];
    }
}