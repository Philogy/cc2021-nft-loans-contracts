// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "./interfaces/IAssetRegistry.sol";
import "./interfaces/IAssetRegistrar.sol";

contract AssetRegistry is IAssetRegistry {
    address public immutable loanTracker;
    uint256 public override totalAssets;
    mapping(uint256 => address) public override assetRegistrarOf;

    constructor(address _loanTracker) {
        loanTracker = _loanTracker;
    }

    function registerAsset() external override returns (uint256) {
        uint256 newAssetId = ++totalAssets;
        assetRegistrarOf[newAssetId] = msg.sender;
        return newAssetId;
    }

    function releaseAssetTo(uint256 _assetId, address _recipient) external override {
        require(msg.sender == loanTracker, "AssetRegistry: not loan tracker");
        address registrar = assetRegistrarOf[_assetId];
        require(registrar != address(0), "AssetRegistry: invalid asset");
        assetRegistrarOf[_assetId] = address(0);
        IAssetRegistrar(registrar).releaseTo(_assetId, _recipient);
    }

    function isValidAsset(uint256 _assetId) public view override returns (bool) {
        return assetRegistrarOf[_assetId] != address(0);
    }
}