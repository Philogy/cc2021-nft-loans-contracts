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
}
