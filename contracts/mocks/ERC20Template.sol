// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Template is ERC20, Ownable {
    constructor(
        string memory _name,
        string memory _symbol,
        address _initialOwner,
        uint256 _initialSupply
    ) ERC20(_name, _symbol) Ownable() {
        _mint(_initialOwner, _initialSupply);
        transferOwnership(_initialOwner);
    }

    function mint(uint256 _amount) external onlyOwner {
        _mint(msg.sender, _amount);
    }
}
