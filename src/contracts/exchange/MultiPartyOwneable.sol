// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is a requester (an owner) and a worker (another owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the requester account will be the one that deploys the contract.  This can never be changed, however
 * the ownership of the second owner (the worker) can later be changed with transferOwnership.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyContractOwner` and `onlyContractWorker` which can be applied to your functions to restrict their use to
 * their respective owners.
 */
abstract contract MultiPartyOwneableOwnable is Context {
    address private _owner; //Requester
    address private _worker; // Worker

    event OwnershipTransferred(address indexed previousWorker, address indexed newWorker);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address worker) {
        address msgSender = _msgSender();
        _owner = msgSender;
        _worker = worker;

        emit OwnershipTransferred(address(0), _worker);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function worker() public view virtual returns (address) {
        return _worker;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyWorker() {
        require(worker() == worker(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyWorker {
        emit OwnershipTransferred(_worker, address(0));
        _worker = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newWorker) public virtual onlyOwner {
        //We allow the contract to be transferred to address (0) to
        //signify there is no current worker for the contract
        //require(newWorker != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_worker, newWorker);
        _worker = newWorker;
    }
}
