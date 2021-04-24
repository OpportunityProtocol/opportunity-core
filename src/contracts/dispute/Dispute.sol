// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../exchange/WorkRelationship.sol";

contract Dispute {
    constructor() {}
    event DisputeCreated(address indexed _submitter, address indexed _aggressor, WorkRelationship indexed _relationship);
    event DisputeResolved(address indexed _submitter, address indexed _aggressor, WorkRelationship indexed _relationship);

    function createDispute(address ) external {
        DisputeCreated(_submitter, _aggressor, _relationship);
    }
    function endDispute() external {
        DisputeResolved(_submitter, _aggressor, _relationship);
    }
}