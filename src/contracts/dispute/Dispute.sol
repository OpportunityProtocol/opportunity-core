// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../exchange/WorkRelationship.sol";

contract Dispute {
    constructor() {}
    event DisputeCreated(address indexed _submitter, address indexed _aggressor, WorkRelationship _relationship);

    mapping(address => address) private disputers;

    constructor() {}

    function createDispute(address ) external {
        DisputeCreated(_submitter, _aggressor, _relationship);
    }
    function endDispute() external {}
}