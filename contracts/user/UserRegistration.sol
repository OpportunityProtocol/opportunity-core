// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./UserSummaryFactory.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * UserRegistration
 * Factory and registrar contract for users
 */
contract UserRegistration is UserSummaryFactory {
    event UserRegistered(address indexed universalAddress);
    event UserAssignedTrueIdentification(address indexed universalAddress, address indexed userSummaryContractAddress);

    mapping(address => address) public _trueIdentifcations;

    /**
     * registerNewUser
     * Registers a new users and assigns a true identification 
     * based on the UserSummary contract created
     */
    function registerNewUser() external {
        require(_trueIdentifcations[msg.sender] == address(0), "A user has already been registered with this address.");

        address userSummaryContractAddress = _createUserSummary(msg.sender);

        assignTrueUserIdentification(msg.sender, userSummaryContractAddress);
        emit UserRegistered(msg.sender);
     }

    /**
     * assignTrueUserIdentification
     * @param _universalAddress The address the register transaction was sent from
     * @param _summaryContractAddress The address of the user summary contract deplyoed
     */
    function assignTrueUserIdentification(address _universalAddress, address _summaryContractAddress) internal {
        _trueIdentifcations[_universalAddress] = _summaryContractAddress;
        assert(_trueIdentifcations[_universalAddress] == _summaryContractAddress);
        emit UserAssignedTrueIdentification(_universalAddress, _summaryContractAddress);
    }
    /**
     * getTrueIdentification
     * @param universalAddress The address of the user's wallet
     * @return Returns the user summary address mapped to the user's wallet
     */
    function getTrueIdentification(address universalAddress) external view returns(address) {
        return _trueIdentifcations[universalAddress];
    }
}