// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./UserSummaryFactory.sol";

contract UserRegistration {

    //maps a civic address to a universal generated address
    mapping(string => address) private _universalAddress;
    mapping(string => bool) private _hasUniversalAddress;

    event UserRegistered(string indexed civicID, string indexed universalAddress);

    constructor() {}

    /**
     * registerNewUser
     * Registers a new user to the platform based on their civicID.
     * @param _civicID
     * @param _newUniversalAddress
     */
     function registerNewUser(string memory civicID, address newUniversalAddress) public returns(bool) {
        bool hasAssignedUniversalAddressResult = assignUniversalAddress(civicID, newUniversalAddress);
        require(hasAssignedUniversalAddressResult == false);

        UserSummaryFactory factory = new UserSummaryFactory();
        factory.createUserSummary(civicID);
     }

    /**
     * assignUniversalAddress
     * Maps a users civic id to the universal address for the platform.
     * @param _civicID
     * @param _newUniversalAddress
     */
    function assignUniversalAddress(string memory civicID, address newUniversalAddress) public returns(bool) {
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
     * @param _civicID
     * @return bool based on if a user has a universal address or not.
     */
    function hasUniversalAddress(string memory civicID) public view returns(bool) {
        return _hasUniversalAddress[civicID];
    }
}