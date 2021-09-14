// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../interfaces/IAssetRegistrar.sol";
import "../interfaces/IAssetRegistry.sol";

contract ERC721Registrar is IAssetRegistrar, IERC721Receiver {
    address internal immutable registry;

    struct Token {
        IERC721 collection;
        uint256 id;
    }

    mapping(uint256 => Token) public tokenOf;

    constructor(address _registry) {
        registry = _registry;
    }

    function onERC721Received(address, address, uint256 _tokenId, bytes calldata)
        external override returns (bytes4)
    {
        uint256 assetId = IAssetRegistry(registry).registerAsset();
        tokenOf[assetId] = Token({
            collection: IERC721(msg.sender),
            id: _tokenId
        });
        return this.onERC721Received.selector;
    }

    function releaseTo(uint256 _assetId, address _recipient) external override {
        require(msg.sender == registry, "ERC721Registrar: not registry");
        Token storage token = tokenOf[_assetId];
        token.collection.safeTransferFrom(address(this), _recipient, token.id);
        delete tokenOf[_assetId];
    }
}
