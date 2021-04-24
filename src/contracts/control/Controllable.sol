// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Controllable {
    address private _globalController;

    constructor(address globalController) {
        _globalController = globalController;
     }

     modifier onlyGlobalController(address requester) {
         require(requester == _globalController);
         _;
     }

}