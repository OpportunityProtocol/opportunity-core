// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../exchange/WorkRelationship.sol";

contract Dispute {
    constructor() {}
    event DisputeCreated(address indexed _submitter, address indexed _aggressor, address indexed _relationship);
    event DisputeResolved(address indexed _submitter, address indexed _aggressor, address indexed _relationship);

    function createDispute(address submitter, address aggressor, address relationship) external {
        DisputeCreated(submitter, aggressor, relationship);
    }
    function endDispute(address submitter, address aggressor, address relationship) external {
        DisputeResolved(submitter, aggressor, relationship);
    }
}