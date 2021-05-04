// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/Market.sol";

contract Controllable {
    address private _globalController;

    constructor() {
        _globalController = msg.sender;
     }

     modifier onlyGlobalController(address requester) {
         require(requester == _globalController);
         _;
     }

     modifier onlyDefaultMarkets(MarketUtil.MarketType marketType) {
         require(marketType == MarketUtil.MarketType.DEFAULT);
        _;
     }

     modifier onlyCustomMarkets(MarketUtil.MarketType marketType) {
          require(marketType == MarketUtil.MarketType.CREATED);
         _;
     }

     modifier onlyNotPausedState(MarketUtil.MarketStatus marketStatus) {
         require(marketStatus != MarketUtil.MarketStatus.PAUSED);
         _;
     }

      modifier onlyPausedState(MarketUtil.MarketStatus marketStatus) {
         require(marketStatus == MarketUtil.MarketStatus.ACTIVE);
         _;
     }

}