// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./WorkExchange.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WorkRelationship is WorkExchange {
    // Status of the current contract
    string private _contractStatus;

    // Work evaluation
    string private _evaluation;

    // Task address
    address private _taskAddress;

    // Task solution pointer
    string private _taskPointer;

    // Address of the current worker
    address private _currentWorker;

    constructor() WorkExchange(address payable requesterBeneficiary, address payable workerBeneficiary, bool isTimeLocked) {
        setCurrentWorker(workerBeneficiary);
    }

    function checkWorkerEvaluation() public {

    }

    function setCurrentWorker(address newWorker) public {
        _currentWorker = newWorker;
    }

    function defaultWorker() public {
        setCurrentWorker(address(0));
    }
}