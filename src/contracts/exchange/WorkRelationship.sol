// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./WorkExchange.sol";
import "../user/UserSummary.sol";
import "../libraries/Evaluation.sol";
import "../libraries/Market.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WorkRelationship is Ownable {
    event WorkRelationshipCreated(string indexed _owner, Market.MarketUtil.MarketType indexed, address indexed _relationship);
    event WorkRelationshipEnded(string indexed _owner, Market.MarketUtil.MarketType indexed _marketType, address indexed _relationship);

    // Status of the current contract
    string private _contractStatus;
    // Task solution pointer
    string private _taskPointer;

    constructor(string memory _taskPointer, Evaluation.EvaluationState) {
        bool passesEvaluation = checkWorkerEvaluation(newWorker, evaluationState);
        require(passesEvaluation == true);

        WorkRelationshipCreated(_owner, _marketType, address(this));
    }

    function createWorkExchange(address payable workerBeneficiary, bool isTimeLocked) external {
        bool passesEvaluation = checkWorkerEvaluation(newWorker, evaluationState);
        require(passesEvaluation == true);

        WorkExchange workExchange = new WorkExchange(_owner, workerBeneficiary, isTimeLocked);
    }

    function checkWorkerEvaluation(address workerUniversalAddress, Evaluation.EvaluationState memory evaluationState) internal returns(bool) {
        bool passesEvaluation = UserSummary(workerUniversalAddress).evaluateUser(evaluationState);
        return passesEvaluation;
    }

    function defaultWorker() private {
        setCurrentWorker(address(0));
    }

    function disableWorkRelationship() public onlyOwner {
        require(_contractStatus == Evaluation.WorkRelationshipState.COMPLETED || _contractStatus == Evaluation.WorkRelationshipState.COMPLETED);
        WorkRelationshipEnded(_owner, _marketType, address(this));
        selfdestruct();
    }

    function gettaskPointer() view external returns(string) {
        return _taskPointer;
    }
}