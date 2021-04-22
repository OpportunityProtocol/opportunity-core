// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interface/IUserSummary.sol";
import "../market/Market.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UserSummary is IUserSummary {
    string private _civicID;
    uint256 private _userReputation;

    Profile private _userProfile;
    Market[] createdMarkets;
    WorkerTaskGeneralDescription private _workerTaskGeneralDescription;
    RequesterTaskGeneralDescription private _requesterTaskGeneralDescription;

    constructor(string memory _civicIDIn) {
        _civicID = _civicIDIn;
        _userReputation = 1;
        _userProfile.profession = "";
        _userProfile.activityLevel = 0;

        _workerTaskGeneralDescription.taskCompleted = 0;
        _requesterTaskGeneralDescription.taskAssigned = 0;
    }

    modifier onlyAuthenticatedUser(uniqueID) {
        require(uniqueID == _civicID);
        _;
    }

    /**
     *
     */
    function getUserProfile() external view override returns (string[] memory, string memory, uint8) {
        return (_userProfile.skills, _userProfile.profession, _userProfile.activityLevel);
    }

    function createMarket(address market) external {
        createdMarkets.push(market);
    }

    /**
     *
     */
    function updateProfile(Profile memory updatedProfile, string memory civicID) external override onlyAuthenticatedUser(civicID) {
        _userProfile = updatedProfile;
    }

    /**
     *
     */
    function evaluateUser(Evaluation.EvaluationState memory evaluationState) external override returns(bool) {

    }

    /**
     *
     */
     function getContractAddress() public view override returns(address) {
         return address(this);
     }
}
