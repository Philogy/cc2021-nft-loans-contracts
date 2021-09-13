// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./libs/Loans.sol";

contract LoanTracker {
    using Loans for Loans.Loan;
    using SafeCast for *;

    mapping(uint256 => Loans.Loan) public loans;
    uint256 public totalLoansIssued;

    function createLoan(
        uint256 _duration,
        uint256 _eraDuration,
        uint256 _interestRate,
        uint256 _startTime,
        uint256 _principal,
        uint256 _minPayment
    )
        external
    {
        require(_eraDuration > 0, "LoanTracker: era duration 0");
        Loans.Loan storage loan = loans[totalLoansIssued++];
        loan.status = Loans.Status.Open;
        loan.duration = _duration.toUint32();
        loan.eraDuration = _eraDuration.toUint16();
        loan.interestRate = _interestRate.toUint32();
        loan.startTime = _startTime.toUint32();
        loan.outstanding = _principal.toUint128();
        loan.minPayment = _minPayment.toUint128();
    }
}
