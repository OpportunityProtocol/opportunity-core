// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

library MarketLib {
    enum MarketType { 
        DEFAULT,
        CREATED
    }

    enum MarketStatus {
        ACTIVE,
        PAUSED
    }
}