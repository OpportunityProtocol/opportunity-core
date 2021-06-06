// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./interface/IUserSummary.sol";

contract UserSummary is IUserSummary {
    event UserSummaryUpdate(string uniqueHash);

    string private _uniqueHash;
    uint256 private _userReputation;

    Profile private _userProfile;
    address[] private createdMarkets;
    WorkerTaskGeneralDescription private _workerTaskGeneralDescription;
    RequesterTaskGeneralDescription private _requesterTaskGeneralDescription;

    constructor(string memory _uniqueHashIn) {
        _uniqueHash = _uniqueHashIn;
        _userReputation = 1;

        _workerTaskGeneralDescription.taskCompleted = 0;
        _requesterTaskGeneralDescription.taskAssigned = 0;
    }

   /**
     *
     */
    function getUserProfile() external view override returns (string[] memory, string memory, uint8) {
        return (_userProfile.skills, _userProfile.profession, _userProfile.activityLevel);
    }

   /**
     *
     */
    function createMarket(address market) external {
        createdMarkets.push(market);
        emit UserSummaryUpdate(_uniqueHash);
    }

    /**
     *
     */
    function updateProfile(Profile memory updatedProfile, string memory uniqueHash) external override onlyAuthenticatedUser(uniqueHash, _uniqueHash) {
        _userProfile = updatedProfile;
        emit UserSummaryUpdate(_uniqueHash);
    }

   /**
     *
     */
    function getContractAddress() public view returns(address) {
        return address(this);
    }

    /**
     *
     */
    function evaluateUser(Evaluation.EvaluationState memory evaluationState) external override returns(bool) {}
}
