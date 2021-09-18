// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/PaymentsManager.sol";
import "./lib/Loans.sol";
import "./interfaces/IAssetRegistry.sol";
import "./interfaces/ILoanRightsRegistry.sol";
import "./interfaces/ILoanTracker.sol";


contract LoanTracker is ILoanTracker, PaymentsManager {
    using Loans for Loans.Loan;
    using SafeCast for *;

    struct LoanAgreement {
        Loans.Loan loan;
        IERC20 denomintation;
        uint256 assetId;
    }

    IAssetRegistry internal immutable assetRegistry;
    ILoanRightsRegistry internal immutable rightsRegistry;
    mapping(uint256 => LoanAgreement) public loans;
    uint256 public totalLoansIssued;

    constructor(address _assetRegistry, address _rightsRegistry) {
        assetRegistry = IAssetRegistry(_assetRegistry);
        rightsRegistry = ILoanRightsRegistry(_rightsRegistry);
    }

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
    )
        external override
    {
        assetRegistry.reserve(_assetId);
        LoanAgreement storage agreement = loans[totalLoansIssued++];
        agreement.denomintation = _denomination;
        agreement.assetId = _assetId;
        agreement.loan.init(
            _duration.toUint32(),
            _eraDuration.toUint16(),
            _interestRate.toUint32(),
            _startTime.toUint32(),
            _principal.toUint128(),
            _minPayment.toUint128()
        );
        rightsRegistry.register(_lender, _borrower);
    }

    function payDown(uint256 _loanId, uint256 _totalAmount, uint256 _eras)
        external override
    {
        uint32 eras = _eras.toUint32();
        LoanAgreement storage agreement = loans[_loanId];
        _assignAvailableTo(
            agreement.denomintation,
            _totalAmount,
            rightsRegistry.lenderOf(_loanId)
        );
        agreement.loan.payDown(_totalAmount, eras);
    }

    function payCurrent(uint256 _loanId, uint256 _amount) external override {
        LoanAgreement storage agreement = loans[_loanId];
        _assignAvailableTo(
            agreement.denomintation,
            _amount,
            rightsRegistry.lenderOf(_loanId)
        );
        agreement.loan.payCurrent(_amount);
    }

    function payNext(uint256 _loanId, uint256 _amount) external override {
        LoanAgreement storage agreement = loans[_loanId];
        _assignAvailableTo(
            agreement.denomintation,
            _amount,
            rightsRegistry.lenderOf(_loanId)
        );
        agreement.loan.payNext(_amount);
    }

    function defaultOn(uint256 _loanId) external override {
        _checkIsBorrowerOf(_loanId);
        loans[_loanId].loan.setDefaulted();
        rightsRegistry.deleteBorrowerOf(_loanId);
    }

    function forceDefaultOn(uint256 _loanId) external override {
        _checkIsLenderOf(_loanId);
        loans[_loanId].loan.tryDefault(_getTimestamp());
        rightsRegistry.deleteBorrowerOf(_loanId);
    }

    function close(uint256 _loanId) external override {
        loans[_loanId].loan.tryClose();
    }

    function releaseCollateralTo(uint256 _loanId, address _recipient)
        external override
    {
        Loans.Loan storage loan = loans[_loanId].loan;
        require(loan.isComplete(), "LoanTracker: Not yet complete");
        if (loan.isPayedOff()) {
            _checkIsBorrowerOf(_loanId);
            rightsRegistry.deleteBorrowerOf(_loanId);
        } else {
            _checkIsLenderOf(_loanId);
        }
        uint256 assetId = loans[_loanId].assetId;
        delete loans[_loanId];
        rightsRegistry.deleteLenderOf(_loanId);
        assetRegistry.releaseAssetTo(assetId, _recipient);
    }

    function _checkIsBorrowerOf(uint256 _loanId) internal view {
        require(
            rightsRegistry.isBorrowerOf(_loanId, msg.sender),
            "LoanTracker: Not borrower"
        );
    }

    function _checkIsLenderOf(uint256 _loanId) internal view {
        require(
            rightsRegistry.isLenderOf(_loanId, msg.sender),
            "LoanTracker: Not lender"
        );
    }

    function _authPayment(address _owner) internal override view returns (bool) {
        return _owner == msg.sender
            || rightsRegistry.isApprovedForAll(_owner, msg.sender);
    }

    function _getTimestamp() internal virtual view returns (uint256) {
        return block.timestamp;
    }
}
