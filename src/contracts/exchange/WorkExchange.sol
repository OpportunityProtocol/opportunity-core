//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "./DaiEscrow.sol";

contract WorkExchange is DaiEscrow {
    constructor(
        address _depositor,
        uint _wad, 
        address _daiTokenAddress) 
    DaiEscrow(_depositor, _wad, _daiTokenAddress) {
        
    }

    function disputeFunds(address callee) external {
        updateStatus(callee);
    }
}