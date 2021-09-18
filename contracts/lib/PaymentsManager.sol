// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PaymentsManager {
    using SafeERC20 for IERC20;

    mapping(IERC20 => uint256) internal storedBalanceOf;
    mapping(IERC20 => mapping(address => uint256)) internal pendingBalanceOf;

    function skimTo(IERC20 _token, address _recipient) public {
        _token.safeTransfer(_recipient, _getAvailable(_token));
    }

    function releasePendingBalance(
        IERC20 _token,
        address _owner,
        uint256 _amount
    )
        external
    {
        require(_authPayment(_owner), "Payments: Not authorized");
        uint256 ownerBalance = pendingBalanceOf[_token][_owner];
        require(ownerBalance >= _amount, "Payments: Insufficient balance");
        storedBalanceOf[_token] -= _amount;
        pendingBalanceOf[_token][_owner] = ownerBalance - _amount;
    }

    function _assignAvailableTo(
        IERC20 _token,
        uint256 _amount,
        address _recipient
    )
        internal
    {
        uint256 storedBal = storedBalanceOf[_token];
        uint256 realBalance = _token.balanceOf(address(this));
        uint256 usedBalance = storedBal + _amount;
        require(realBalance >= usedBalance, "Payments: Insufficient balance");
        storedBalanceOf[_token] = usedBalance;
        pendingBalanceOf[_token][_recipient] += _amount;
    }

    function _getAvailable(IERC20 _token) internal view returns (uint256) {
        return _token.balanceOf(address(this)) - storedBalanceOf[_token];
    }

    function _authPayment(address _owner) internal virtual returns (bool) {
        return msg.sender == _owner;
    }
}
