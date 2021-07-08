// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./interface/IUserSummary.sol";

contract UserSummary is IUserSummary {
    event UserSummaryUpdate(address universalAddress);

    address private _universalAddress;
    uint256 private _userReputation;

    Profile private _userProfile;
    address[] private createdMarkets;
    WorkerTaskGeneralDescription private _workerTaskGeneralDescription;
    RequesterTaskGeneralDescription private _requesterTaskGeneralDescription;

    constructor(address universalAddress) {
        _universalAddress = universalAddress;
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
        emit UserSummaryUpdate(_universalAddress);
    }

    /**
     *
     */
    function updateProfile(Profile memory updatedProfile, address universalAddress) external override {
        _userProfile = updatedProfile;
        emit UserSummaryUpdate(universalAddress);
    }

    /**
     *
     */
    function evaluateUser(Evaluation.EvaluationState memory evaluationState) external override returns(bool) {}
}
