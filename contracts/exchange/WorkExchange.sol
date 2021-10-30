//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "./DaiEscrow.sol";

contract WorkExchange is DaiEscrow {
    constructor(
        address _depositor,
        address _beneficiary,
        uint _wad,
        address _daiTokenAddress,
        address _cDaiTokenAddress,
        address _banker,
        uint256 nonce,
        uint256 expiry,
        uint8 eV,
        bytes32 eR,
        bytes32 eS) 
        DaiEscrow(
        _depositor,
         _beneficiary, 
         _wad, 
         _daiTokenAddress, 
         _cDaiTokenAddress, 
         _banker,
         nonce,
         expiry,
         eV,
         eR,
         eS
         ) {
        
    }
}