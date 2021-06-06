// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract TimeLocked {
    event EnableTimeLock();
    event DisableTimeLock();
    event LockExpired();

    bool private _lockStatus;

    constructor(bool isTimeLocked) {
        _lockStatus = isTimeLocked;
    }

    function lock() public {
        require(_lockStatus != true);
        emit EnableTimeLock();
    }

    function unlock() public {
        require(_lockStatus != false);
        emit DisableTimeLock();
    }

    function lockExpired() public {
        unlock();
        emit LockExpired();
    }
}