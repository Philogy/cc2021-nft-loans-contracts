// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {
    uint256 public totalSupply;

    constructor() ERC721("Mock ERC721 Token", "MNFT") { }

    function mint(address _recipient, uint256 _tokenId) external {
        totalSupply++;
        _safeMint(_recipient, _tokenId);
    }

    function mintMany(uint256 _amount) external {
        uint256 firstTokenId = totalSupply;
        for (uint256 i; i < _amount; i++) {
            _safeMint(msg.sender, firstTokenId + i);
        }
        totalSupply = firstTokenId + _amount;
    }
}
