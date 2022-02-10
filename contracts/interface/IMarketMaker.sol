// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract IMarketMaker {
    event MarketCreated(uint256 indexed marketID, address indexed market, address creator);

    function createMarket(string calldata _marketName) external virtual returns(uint256);
}