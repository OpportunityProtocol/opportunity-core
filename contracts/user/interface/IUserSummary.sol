// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../../libraries/Evaluation.sol";

interface IUserSummary {
    struct EmployerDescription {
        uint256 contractsEntered;
        uint256 contractsCompleted;
    }

    struct WorkerDescription {
        uint256 tipsEarned;
        uint256 contractsEntered;
        uint256 contractsCompleted;
    }
}