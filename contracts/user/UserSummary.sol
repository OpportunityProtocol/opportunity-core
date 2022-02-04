// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./interface/IUserSummary.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UserSummary is IUserSummary {

    event UserSummaryUpdate(address universalAddress);

    address public owner;
    EmployerDescription employerDescription;
    WorkerDescription workerDescription;

    constructor(address universalAddress) {
        owner = universalAddress;
    }
}

