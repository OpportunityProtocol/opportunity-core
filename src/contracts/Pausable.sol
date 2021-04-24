// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Pausable {
    bool _isPaused = false;
    address private _owner;

    constructor(address contractOwner) {
        _isPaused = false;
        _owner = contractOwner;
    }

        /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller is not the owner");
        _;
    }


    modifier onlyNotPausedState {
        require(_isPaused == false);
        _;
    }

    modifier onlyPausedState {
        require(_isPaused == true);
        _;
    }

    function setPaused(bool paused) public onlyOwner {
        _isPaused = paused;
    }
}