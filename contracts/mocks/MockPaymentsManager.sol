// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/PaymentsManager.sol";

/// @author Philippe Dumonet
contract MockPaymentsManager is PaymentsManager {
    function assignAvailableTo(IERC20 _token, uint256 _amount, address _recipient)
        external
    {
        _assignAvailableTo(_token, _amount, _recipient);
    }

    function setStoredBalance(IERC20 _token, uint256 _amount) external {
        _setStoredBalance(_token, _amount);
    }

    function getAvailable(IERC20 _token) public view returns (uint256) {
        return _getAvailable(_token);
    }
}
