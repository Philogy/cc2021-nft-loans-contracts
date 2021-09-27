// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "./ERC20Template.sol";

contract ERC20Factory {
    event CreatedToken(address indexed newToken, address indexed creator);

    function createToken(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) external {
        ERC20Template newToken = new ERC20Template(
            _name,
            _symbol,
            msg.sender,
            _initialSupply
        );
        emit CreatedToken(address(newToken), msg.sender);
    }
}
