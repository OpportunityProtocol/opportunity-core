// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./UserSummaryFactory.sol";

contract UserRegistration { //FU SUV

    //maps a unique authentication hash address to a universal generated address
    mapping(string => address) private _universalAddress;

    // Mapping of UniqueHash to universal address existing status
    mapping(string => bool) private _uniqueHashes;

    // Mapping of universal address to summary contract address
    mapping(address => address) private _trueIdentifcations;

    event UserRegistered(string indexed uniqueHash, address indexed universalAddress);
    event UserAssignedTrueIdentification(string indexed trueIdentification, address indexed universalAddress);

    constructor() {}

    /**
     * registerNewUser
     * Registers a new user to the platform based on their uniqueHash.
     * @param uniqueHash Hash returned from civic identity wallet
     * @param newUniversalAddress Universal user address
     */
     function registerNewUser(string memory uniqueHash, address newUniversalAddress) external returns(bool) {
        bool hasAssignedUniversalAddressResult = assignUniversalAddress(uniqueHash, newUniversalAddress);
        require(hasAssignedUniversalAddressResult == false);

        UserSummaryFactory factory = new UserSummaryFactory();
        address userSummaryContractAddress = factory.createUserSummary(uniqueHash);

        assignTrueUserIdentification(newUniversalAddress, userSummaryContractAddress);
     }

    /**
     * assignTrueUserIdentification
     */
    function assignTrueUserIdentification(address universalAddress, address summaryContractAddress) internal returns(bool) {
        emit assignTrueUserIdentification(universalAddress, summaryContractAddress);
        _trueIdentifcations[universalAddress] = summaryContractAddress;
    }

    /**
     * assignUniversalAddress
     * Maps a users civic id to the universal address for the platform.
     * @param uniqueHash Hash returned from civic identity wallet
     * @param newUniversalAddress Universal user address
     */
    function assignUniversalAddress(string memory uniqueHash, address newUniversalAddress) internal returns(bool) {
        //require this address not to already have a universal address
        require(_hasUniversalAddress[uniqueHash] == false);
        //require there to not be a universal address at this index
        require(true == false);

        //assign the civic address to a new universal address
        _universalAddress[uniqueHash] = newUniversalAddress; 
    }

    /**
     * hasUniversalAddress
     * Returns Checks to see if a user has a universal address or not.
     * @param uniqueHash Hash returned from civic identity wallet
     * @return bool based on if a user has a universal address or not.
     */
    function hasUniversalAddress(string memory uniqueHash) internal view returns(bool) {
        return _hasUniversalAddress[uniqueHash];
    }

    function getTrueIdentification(address universalAddress) public {
        return _trueIdentifcations[universalAddress];
    }

    
}