// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/escrow/RefundEscrow.sol";

/**
 *
 * Note: Created for every job acceptance.
 */
contract WorkExchange is Ownable {
    using SafeMath for uint256;

    RefundEscrow private escrow;

    

    constructor(address payable beneficiary) {
        escrow = new RefundEscrow(beneficiary);
    }

    /**
     * Receives payments from customers
     */
    function sendPayment(address payable payee) external payable onlyOwner {
        escrow.withdraw(payee);
    }

    /**
     * Withdraw funds to wallet
     */
    function withdraw() external onlyOwner {
        escrow.beneficiaryWithdraw();
    }

    /**
     * Checks balance available to withdraw
     * @return the balance
     */
    function balance() external view onlyOwner returns (uint256) {
        return escrow.depositsOf(escrow.beneficiary());
    }
}
