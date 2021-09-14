// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./InterestMaths.sol";

library Loans {
    using InterestMaths for uint256;
    using SafeCast for *;

    enum Status { Open, Defaulted, Closed }

    struct Loan {
        Status status;
        uint32 lastPayedEra;
        uint32 duration;
        uint16 eraDuration;
        uint32 interestRate;
        uint32 startTime;
        uint128 outstanding;
        uint128 minPayment;
    }

    uint256 constant internal ERA_DURATION_PREC = 12 hours;

    function payDown(Loan storage _loan, uint256 _totalPayment, uint32 _eras)
        internal
    {
        uint256 minPayment = getMinPayment(_loan);
        uint256 minTotalPayment = _eras * minPayment;
        require(minTotalPayment <= _totalPayment, "LoanTracker: payment below min");
        uint256 interestRate = uint256(_loan.interestRate);
        uint256 outstanding = uint256(_loan.outstanding);
        uint256 firstPayment = _totalPayment - minTotalPayment + minPayment;
        outstanding = outstanding
            .accrue(interestRate, firstPayment)
            .accrueRepeating(interestRate, _eras - 1, minPayment);
        _loan.lastPayedEra += _eras;
        _loan.outstanding = outstanding.toUint128();
    }

    function payNext(Loan storage _loan, uint256 _payment) internal {
        require(getMinPayment(_loan) <= _payment, "LoanTracker: payment below min");
        uint256 interestRate = uint256(_loan.interestRate);
        uint256 outstanding = uint256(_loan.outstanding);
        _loan.outstanding = outstanding.accrue(interestRate, _payment).toUint128();
    }

    function getMinPayment(Loan storage _loan) internal view returns (uint256) {
        return uint256(_loan.minPayment);
    }

    function getCurrentEra(Loan storage _loan) internal view returns (uint256) {
        uint256 eraDuration = uint256(_loan.eraDuration) * ERA_DURATION_PREC;
        uint256 startTime = uint256(_loan.startTime);
        if (block.timestamp < startTime) return 0;
        return (startTime - block.timestamp) / eraDuration;
    }

    function setDefaulted(Loan storage _loan) internal {
        require(isOpen(_loan), "Loans: Not open");
        _loan.status = Status.Defaulted;
    }

    function setClosed(Loan storage _loan) internal {
        require(isOpen(_loan), "Loans: Not open");
        _loan.status = Status.Closed;
    }

    function isOpen(Loan storage _loan) internal view returns (bool) {
        return _loan.status == Status.Open;
    }

    function isDefaulted(Loan storage _loan) internal view returns (bool) {
        return _loan.status == Status.Defaulted;
    }

    function isClose(Loan storage _loan) internal view returns (bool) {
        return _loan.status == Status.Closed;
    }
}
