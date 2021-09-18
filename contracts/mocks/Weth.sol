// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IWeth.sol";

contract Weth is ERC20, IWeth {
    using Address for address payable;

    constructor() ERC20("Wrapped Native token", "WETH") { }

    function deposit() external payable override {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) external override {
        _burn(msg.sender, _amount);
        payable(msg.sender).sendValue(_amount);
    }
}
