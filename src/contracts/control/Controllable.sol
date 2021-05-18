// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/MarketLib.sol";

contract Controllable {
    address private _globalController;

    constructor() {
        _globalController = msg.sender;
     }

     modifier onlyGlobalController(address requester) {
         require(requester == _globalController);
         _;
     }

     modifier onlyDefaultMarkets(MarketLib.MarketType marketType) {
         require(marketType == MarketLib.MarketType.DEFAULT);
        _;
     }

     modifier onlyCustomMarkets(MarketLib.MarketType marketType) {
          require(marketType == MarketLib.MarketType.CREATED);
         _;
     }

     modifier onlyNotPausedState(MarketLib.MarketStatus marketStatus) {
         require(marketStatus != MarketLib.MarketStatus.PAUSED);
         _;
     }

      modifier onlyPausedState(MarketLib.MarketStatus marketStatus) {
         require(marketStatus == MarketLib.MarketStatus.ACTIVE);
         _;
     }

}