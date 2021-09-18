// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IWeth.sol";
import "../lib/UnsafeMulticall.sol";
import "./LoanManagerBorrowLend.sol";

contract LoanManager is LoanManagerBorrowLend, UnsafeMulticall {
    using SafeERC20 for IERC20;
    using SafeERC20 for IWeth;
    using Address for address payable;

    constructor(
        address _loanTracker,
        address _rightsRegistry,
        address _assetRegistry,
        address _nftRegistrar,
        address _weth
    )
        LoanManagerBorrowLend(
            _loanTracker,
            _rightsRegistry,
            _assetRegistry,
            _nftRegistrar,
            _weth
        )
    { }

    modifier onlyBorrowerOf(uint256 _loanId) {
        _checkIsBorrowerOf(_loanId);
        _;
    }

    modifier onlyLenderOf(uint256 _loanId) {
        _checkIsLenderOf(_loanId);
        _;
    }

    function depositNative() external payable {
        weth.deposit{ value: msg.value }();
        weth.safeTransfer(address(loanTracker), msg.value);
    }

    function depositToken(IERC20 _token, uint256 _amount) external {
        _token.safeTransferFrom(msg.sender, address(loanTracker), _amount);
    }

    function releasePending(IERC20 _token, uint256 _amount) external {
        loanTracker.releasePendingBalance(_token, msg.sender, _amount);
    }

    function withdraw(IERC20 _token, address _recipient) external {
        loanTracker.skimAllTo(_token, _recipient);
    }

    function withdrawNative(address payable _recipient) external {
        loanTracker.skimAllTo(weth, address(this));
        uint256 total = weth.balanceOf(address(this));
        weth.withdraw(total);
        _recipient.sendValue(total);
    }

    function payDown(uint256 _loanId, uint256 _total, uint256 _eras)
        external onlyBorrowerOf(_loanId)
    {
        loanTracker.payDown(_loanId, _total, _eras);
    }

    function payNext(uint256 _loanId, uint256 _amount)
        external onlyBorrowerOf(_loanId)
    {
        loanTracker.payNext(_loanId, _amount);
    }

    function payCurrent(uint256 _loanId, uint256 _amount)
        external onlyBorrowerOf(_loanId)
    {
        loanTracker.payCurrent(_loanId, _amount);
    }

    function defaultOn(uint256 _loanId) external onlyBorrowerOf(_loanId) {
        loanTracker.defaultOn(_loanId);
    }

    function forceDefaultOn(uint256 _loanId) external onlyLenderOf(_loanId) {
        loanTracker.forceDefaultOn(_loanId);
    }

    function close(uint256 _loanId) external {
        loanTracker.close(_loanId);
    }

    function releaseCollateralTo(uint256 _loanId, address _recipient) external {
        address releasedFor = loanTracker.releaseCollateralTo(_loanId, _recipient);
        require(releasedFor == msg.sender, "LoanManager: Not releaser");
    }

    function _checkIsBorrowerOf(uint256 _loanId) internal view {
        require(rightsRegistry.lenderOf(_loanId) == msg.sender, "LoanManager: Not borrower");
    }

    function _checkIsLenderOf(uint256 _loanId) internal view {
        require(rightsRegistry.lenderOf(_loanId) == msg.sender, "LoanManager: Not lender");
    }
}
