// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/escrow/RefundEscrow.sol";
import "../TimeLocked.sol";
import "./MultiPartyOwneable.sol";

/**
 * The Work Exchange contract acts as an escrow for the stake from both parties
 * as well as facilitates the exchange of contracts between to users.  A WorkExchange is created everytime a user enters into a new deal or
 * contract.
 * Note: Created for every job acceptance.
 */
contract WorkExchange is MultiPartyOwneableOwnable, TimeLocked {
    using SafeMath for uint256;

    event WorkerSentSolution();
    event RequesterSentPayment();
    event WorkExchangeStarted(address indexed requesterAddress, address indexed workerBeneficiary, address workExchangeAddress);
    event WorkExchangeEnded();

    RefundEscrow private _requesterEscrow;
    RefundEscrow private _workerEscrow;

    address private _workerAddress;
    address private _requesterAddress;

    constructor(address payable requesterBeneficiary, address payable workerBeneficiary, bool isTimeLocked) MultiPartyOwneableOwnable(workerBeneficiary), TimeLockedDepositProtocol(isTimeLocked) {
        _requesterEscrow = new RefundEscrow(requesterBeneficiary);
        _workerEscrow = new RefundEscrow(workerBeneficiary);

        _requesterAddress = requesterBeneficiary;
        _workerAddress = workerBeneficiary;
        emit WorkExchangeStarted(requesterBeneficiary, workerBeneficiary, address(this));
    }

    /**
     * Receives payments from customers
     */
    function sendPaymentAsRequester(address payable payee) external payable onlyOwner {
        _requesterEscrow.withdraw(payee);
        RequesterSentPayment();
    }

    /**
     * Receives payments from customers
     */
    function sendPaymentAsWorker(address payable payee) external payable onlyOwner {
        _workerEscrow.withdraw(payee);
        WorkerSentSolution();
    }

    /**
     * Withdraw funds to wallet
     */
    function withdrawAsRequester() external onlyOwner {
        _requesterEscrow.beneficiaryWithdraw();
    }

    /**
     * Withdraw funds to wallet
     */
    function withdrawAsWorker() external onlyOwner {
        _workerEscrow.beneficiaryWithdraw();
    }

    /**
     * Checks balance available to withdraw
     * @return the balance
     */
    function balanceRequester() external view onlyOwner returns (uint256) {
        return _requesterEscrow.depositsOf(_requesterEscrow.beneficiary());
    }

    /**
     * Checks balance available to withdraw
     * @return the balance
     */
    function balanceWorker() external view onlyOwner returns (uint256) {
        return _workerEscrow.depositsOf(_workerEscrow.beneficiary());
    }

    function disableWorkExchange() internal {
        emit WorkExchangeEnded(_requesterAddress, _workerAddress, address(this));
        selfdestruct();
    }
}
