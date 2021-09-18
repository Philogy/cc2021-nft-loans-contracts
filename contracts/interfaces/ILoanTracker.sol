// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPaymentsManager.sol";

interface ILoanTracker is IPaymentsManager {
    function createLoan(
        uint256 _assetId,
        IERC20 _denomination,
        uint256 _duration,
        uint256 _eraDuration,
        uint256 _interestRate,
        uint256 _startTime,
        uint256 _principal,
        uint256 _minPayment,
        address _lender,
        address _borrower
    ) external;
    function payDown(uint256 _loanId, uint256 _totalAmount, uint256 _eras) external;
    function payCurrent(uint256 _loanId, uint256 _amount) external;
    function payNext(uint256 _loanId, uint256 _amount) external;
    function defaultOn(uint256 _loanId) external;
    function forceDefaultOn(uint256 _loanId) external;
    function close(uint256 _loanId) external;
    function releaseCollateralTo(uint256 _loanId, address _recipient)
        external returns (address releasedFor);
}
