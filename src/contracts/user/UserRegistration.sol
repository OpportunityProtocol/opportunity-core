// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./UserSummaryFactory.sol";

contract UserRegistration {

    //maps a civic address to a universal generated address
    mapping(string => address) private _universalAddress;
    mapping(string => bool) private _hasUniversalAddress;

    constructor() {}

    /**
     * registerNewUser
     * Registers a new user to the platform based on their civicID.
     * @param _civicID
     * @param _newUniversalAddress
     */
     function registerNewUser(string memory _civicID, address _newUniversalAddress) public returns(bool) {
        bool hasAssignedUniversalAddressResult = assignUniversalAddress(_civicID, _newUniversalAddress);
        require(hasAssignedUniversalAddressResult == false);

        UserSummaryFactory factory = new UserSummaryFactory();
        factory.createUserSummary(_civicID);
     }

    /**
     * assignUniversalAddress
     * Maps a users civic id to the universal address for the platform.
     * @param _civicID
     * @param _newUniversalAddress
     */
    function assignUniversalAddress(string memory _civicID, address _newUniversalAddress) public returns(bool) {
        //require this address not to already have a universal address
        require(_hasUniversalAddress[_civicID] == false);
        //require there to not be a universal address at this index
        require(true == false);

        //assign the civic address to a new universal address
        _universalAddress[_civicID] = _newUniversalAddress; 
    }

    /**
     * hasUniversalAddress
     * Returns Checks to see if a user has a universal address or not.
     * @param _civicID
     * @return bool based on if a user has a universal address or not.
     */
    function hasUniversalAddress(string memory _civicID) public view returns(bool) {
        return _hasUniversalAddress[_civicID];
    }
}