// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

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