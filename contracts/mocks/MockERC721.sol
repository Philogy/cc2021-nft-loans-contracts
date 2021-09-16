// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {
    constructor() ERC721("Mock ERC721 Token", "MNFT") { }

    function mint(address _recipient, uint256 _tokenId) external {
        _safeMint(_recipient, _tokenId);
    }
}
