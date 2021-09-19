// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IPaymentsManager.sol";

abstract contract PaymentsManager is IPaymentsManager {
    using SafeERC20 for IERC20;

    mapping(IERC20 => uint256) public override storedBalanceOf;
    mapping(IERC20 => mapping(address => uint256)) public override pendingBalanceOf;

    function skimAllTo(IERC20 _token, address _recipient) external override {
        _token.safeTransfer(_recipient, _getAvailable(_token));
    }

    function skimTo(IERC20 _token, uint256 _amount, address _recipient)
        external override
    {
        require(_amount <= _getAvailable(_token), "Payments: Insufficient excess");
        _token.safeTransfer(_recipient, _amount);
    }

    function releasePendingBalance(
        IERC20 _token,
        address _owner,
        uint256 _amount
    ) external override {
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
        _setStoredBalance(_token, storedBalanceOf[_token] + _amount);
        pendingBalanceOf[_token][_recipient] += _amount;
    }

    function _getAvailable(IERC20 _token) internal view returns (uint256) {
        return _token.balanceOf(address(this)) - storedBalanceOf[_token];
    }

    function _authPayment(address _owner) internal virtual returns (bool) {
        return msg.sender == _owner;
    }

    function _setStoredBalance(IERC20 _token, uint256 _balance) internal {
        uint256 realBalance = _token.balanceOf(address(this));
        require(realBalance >= _balance, "Payments: Insufficient balance");
        storedBalanceOf[_token] = _balance;
    }
}
