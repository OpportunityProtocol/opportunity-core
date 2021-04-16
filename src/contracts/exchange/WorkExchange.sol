// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/escrow/RefundEscrow";

contract WorkExchange is RefundEscrow {
    constructor(address payable beneficiary_) {
        super(beneficiary_);
    }
    
}