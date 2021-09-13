// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

library InterestMaths {
    uint256 constant internal SCALE = 1e6;

    function fmul(uint256 _fX, uint256 _y) internal pure returns (uint256) {
        return _fX * _y / SCALE;
    }

    function fdiv(uint256 _x, uint256 _fY) internal pure returns (uint256) {
        return _x * SCALE / _fY;
    }

    function accrue(
        uint256 _interestRate,
        uint256 _outstanding,
        uint256 _payment
    ) internal pure returns (uint256) {
        return accrue(_interestRate, _outstanding) - _payment;
    }

    function accrue(uint256 _outstanding, uint256 _interestRate)
        internal pure returns (uint256)
    {
        uint256 interest = fmul(_interestRate, _outstanding);
        return _outstanding + interest;
    }

    function accrueRepeating(
        uint256 _outstanding,
        uint256 _interestRate,
        uint256 _repetitions,
        uint256 _payment
    ) internal pure returns (uint256) {
        uint256 infPayment = fdiv(_payment, _interestRate);
        uint256 totalInterest = exp(SCALE + _interestRate, _repetitions);

        if (infPayment > _outstanding) {
            uint256 diff = infPayment - _outstanding;
            return infPayment - fmul(totalInterest, diff);
        } else {
            uint256 diff = _outstanding - infPayment;
            return infPayment + fmul(totalInterest, diff);
        }
    }

    function exp(uint256 _fBase, uint256 _exp) internal pure returns (uint256) {
        uint256 acc = _fBase * SCALE;
        for (uint256 i; i < _exp; i++) acc = fmul(acc, _fBase);
        return acc / SCALE;
    }
}
