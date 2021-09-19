// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @author Philippe Dumonet
contract MockERC20 is ERC20 {
    constructor() ERC20("Mock test token", "MTT") { }

    function mint(address _recipient, uint256 _amount) external {
        _mint(_recipient, _amount);
    }
}
