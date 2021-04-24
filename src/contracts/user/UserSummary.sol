// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interface/IUserSummary.sol";
import "../market/Market.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UserSummary is IUserSummary {
    event UserSummaryUpdate(address indexed userAddress, string uniqueHash);

    string private _uniqueHash;
    uint256 private _userReputation;

    Profile private _userProfile;
    Market[] createdMarkets;
    WorkerTaskGeneralDescription private _workerTaskGeneralDescription;
    RequesterTaskGeneralDescription private _requesterTaskGeneralDescription;

    constructor(string memory _uniqueHashIn) {
        _uniqueHash = _uniqueHashIn;
        _userReputation = 1;

        _workerTaskGeneralDescription.taskCompleted = 0;
        _requesterTaskGeneralDescription.taskAssigned = 0;
    }

    modifier onlyAuthenticatedUser(uniqueID) {
        require(uniqueID == _uniqueHash);
        _;
    }

    function getUserProfile() external view override returns (string[] memory, string memory, uint8) {
        return (_userProfile.skills, _userProfile.profession, _userProfile.activityLevel);
    }

    function createMarket(address market) external {
        createdMarkets.push(market);
        emit UserSummaryUpdate(_uniqueHash);
    }

    /**
     *
     */
    function updateProfile(Profile memory updatedProfile, string memory uniqueHash) external override onlyAuthenticatedUser(uniqueHash) {
        _userProfile = updatedProfile;
        emit UserSummaryUpdate(_uniqueHash);
    }

    /**
     *
     */
    function evaluateUser(Evaluation.EvaluationState memory evaluationState) external override returns(bool) {

    }
}
