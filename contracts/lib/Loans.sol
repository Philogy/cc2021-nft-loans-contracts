// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "hardhat/console.sol";
import "./InterestMaths.sol";

library Loans {
    using InterestMaths for uint256;
    using SafeCast for *;

    enum Status { Uninitialized, Open, Defaulted, PayedOff }

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

    uint256 constant internal ERA_UNIT_DURATION = 12 hours;

    function init(
        Loan storage _loan,
        uint32 _duration,
        uint16 _eraDuration,
        uint32 _interestRate,
        uint32 _startTime,
        uint128 _principal,
        uint128 _minPayment
    ) internal {
        require(_eraDuration > 0, "Loans: Era duration 0");
        require(_principal > 0, "Loans: No principal");
        _loan.status = Loans.Status.Open;
        _loan.duration = _duration;
        _loan.eraDuration = _eraDuration;
        _loan.interestRate = _interestRate;
        _loan.startTime = _startTime;
        _loan.outstanding = _principal;
        _loan.minPayment = _minPayment;
    }

    function payDown(Loan storage _loan, uint256 _totalPayment, uint32 _eras)
        internal
    {
        checkIsOpen(_loan);
        uint256 minPayment = getMinPayment(_loan);
        uint256 minTotalPayment = _eras * minPayment;
        require(minTotalPayment <= _totalPayment, "Loans: Total payment below min");
        uint256 interestRate = uint256(_loan.interestRate);
        uint256 outstanding = uint256(_loan.outstanding);
        uint256 firstPayment = _totalPayment - minTotalPayment + minPayment;
        outstanding = outstanding
            .accrue(interestRate, firstPayment)
            .accrueRepeating(interestRate, _eras - 1, minPayment);
        _loan.lastPayedEra += _eras;
        _loan.outstanding = outstanding.toUint128();
    }

    function payCurrent(Loan storage _loan, uint256 _payment) internal {
        checkIsOpen(_loan);
        require(_loan.lastPayedEra > 0, "Loans: No current era to pay off");
        _loan.outstanding -= _payment.toUint128();
    }

    function payNext(Loan storage _loan, uint256 _payment) internal {
        checkIsOpen(_loan);
        require(getMinPayment(_loan) <= _payment, "Loans: Payment below min");
        uint256 interestRate = uint256(_loan.interestRate);
        uint256 outstanding = uint256(_loan.outstanding);
        _loan.outstanding = outstanding.accrue(interestRate, _payment).toUint128();
        _loan.lastPayedEra++;
    }

    function getMinPayment(Loan storage _loan) internal view returns (uint256) {
        return uint256(_loan.minPayment);
    }

    function tryDefault(Loan storage _loan, uint256 _timestamp) internal {
        checkIsOpen(_loan);
        uint256 outstanding = uint256(_loan.outstanding);
        require(outstanding > 0, "Loans: Loan payed off");
        uint256 currentEra = getCurrentEra(_loan, _timestamp);
        uint256 totalEras = uint256(_loan.duration);
        require(
            (totalEras > 0 && currentEra >= totalEras) ||
            (_loan.minPayment > 0 && currentEra > uint256(_loan.lastPayedEra)),
            "Loans: Nothing past due"
        );
        _loan.status = Status.Defaulted;
    }

    function tryClose(Loan storage _loan) internal {
        checkIsOpen(_loan);
        uint256 outstanding = uint256(_loan.outstanding);
        require(outstanding == 0, "Loans: Loan not payed off");
        _loan.status = Status.PayedOff;
    }

    function getCurrentEra(Loan storage _loan, uint256 _timestamp)
        internal view returns (uint256)
    {
        uint256 eraDuration = uint256(_loan.eraDuration) * ERA_UNIT_DURATION;
        uint256 startTime = uint256(_loan.startTime);
        if (_timestamp <= startTime) return 0;
        return (_timestamp - startTime) / eraDuration;
    }

    function setDefaulted(Loan storage _loan) internal {
        checkIsOpen(_loan);
        _loan.status = Status.Defaulted;
    }

    function checkIsOpen(Loan storage _loan) internal view {
        require(_loan.status == Status.Open, "Loans: Not open");
    }

    function isPayedOff(Loan storage _loan) internal view returns (bool) {
        return _loan.status == Status.PayedOff;
    }

    function isComplete(Loan storage _loan) internal view returns (bool) {
        Status status = _loan.status;
        return status == Status.PayedOff || status == Status.Defaulted;
    }
}
