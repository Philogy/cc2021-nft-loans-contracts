// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @author Philippe Dumonet
interface IPaymentsManager {
    function skimAllTo(IERC20 _token, address _recipient) external;
    function releasePendingBalance(
        IERC20 _token,
        address _owner,
        uint256 _amount
    ) external;
}
