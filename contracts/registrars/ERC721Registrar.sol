// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../interfaces/IAssetRegistrar.sol";
import "../interfaces/IAssetRegistry.sol";

contract ERC721Registrar is IAssetRegistrar, IERC721Receiver {
    event Registration(
        uint256 indexed assetId,
        address indexed collection,
        uint256 indexed tokenId,
        address sender
    );
    event Release(
        uint256 indexed assetId,
        address indexed collection,
        uint256 indexed tokenId,
        address recipient
    );

    IAssetRegistry internal immutable registry;

    struct Token {
        address collection;
        uint256 id;
    }

    mapping(uint256 => Token) public tokenOf;

    constructor(address _registry) {
        registry = IAssetRegistry(_registry);
    }

    function onERC721Received(
        address,
        address _sender,
        uint256 _tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        _register(msg.sender, _tokenId, _sender);
        return this.onERC721Received.selector;
    }

    function releaseTo(uint256 _assetId, address _recipient) external override {
        require(msg.sender == address(registry), "ERC721Registrar: Not registry");
        Token storage token = tokenOf[_assetId];
        address collection = token.collection;
        uint256 tokenId = token.id;
        emit Release(_assetId, address(collection), tokenId, _recipient);
        delete tokenOf[_assetId];
        // if (_recipient == address(this)) {
        //     _register(newAssetId, collection, tokenId, msg.sender);
        // } else {
        IERC721(collection).safeTransferFrom(address(this), _recipient, tokenId);
        // }
    }

    function _register(
        address _collection,
        uint256 _tokenId,
        address _sender
    ) internal {
        uint256 assetId = registry.registerAsset();
        tokenOf[assetId] = Token({
            collection: _collection,
            id: _tokenId
        });
        emit Registration(assetId, _collection, _tokenId, _sender);
    }
}
