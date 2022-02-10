// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

function initialize(address _employer, address _worker, string memory _extraData, uint256 _wad) external virtual;
function releaseFunds(uint256 _wad) external virtual;
function surrenderFunds() external virtual;