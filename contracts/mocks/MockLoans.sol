// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "../lib/Loans.sol";

contract MockLoans {
    using Loans for Loans.Loan;

    uint256 public totalLoans;
    mapping(uint256 => Loans.Loan) internal loans;

    function getLoan(uint256 _loanId)
        external view returns (Loans.Loan memory)
    {
        return loans[_loanId];
    }

    function createLoan(
        uint32 _duration,
        uint16 _eraDuration,
        uint32 _interestRate,
        uint32 _startTime,
        uint128 _outstanding,
        uint128 _minPayment
    ) external {
        loans[totalLoans++].init(
            _duration,
            _eraDuration,
            _interestRate,
            _startTime,
            _outstanding,
            _minPayment
        );
    }

    function payDown(uint256 _loanId, uint256 _totalPayment, uint32 _eras)
        external
    {
        loans[_loanId].payDown(_totalPayment, _eras);
    }

    function payNext(uint256 _loanId, uint256 _payment)
        external
    {
        loans[_loanId].payNext(_payment);
    }

    function payCurrent(uint256 _loanId, uint256 _payment)
        external
    {
        loans[_loanId].payCurrent(_payment);
    }

    function tryDefault(uint256 _loanId, uint256 _timestamp) external {
        return loans[_loanId].tryDefault(_timestamp);
    }

    function tryClose(uint256 _loanId) external {
        return loans[_loanId].tryClose();
    }

    function setDefaulted(uint256 _loanId) external {
        return loans[_loanId].setDefaulted();
    }

    function getCurrentEra(uint256 _loanId, uint256 _timestamp)
        external view returns (uint256)
    {
        return loans[_loanId].getCurrentEra(_timestamp);
    }

    function getMinPayment(uint256 _loanId) external view returns (uint256) {
        return loans[_loanId].getMinPayment();
    }
}
