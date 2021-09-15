// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "./interfaces/IAssetRegistry.sol";
import "./interfaces/IAssetRegistrar.sol";

contract AssetRegistry is IAssetRegistry {
    address internal immutable loanTracker;
    uint256 public override totalAssets;
    mapping(uint256 => address) public override registrarOf;
    mapping(uint256 => bool) public override reserved;

    constructor(address _loanTracker) {
        loanTracker = _loanTracker;
    }

    function registerAsset() external override returns (uint256) {
        uint256 newAssetId = totalAssets++;
        registrarOf[newAssetId] = msg.sender;
        emit Registration(msg.sender, newAssetId);
        return newAssetId;
    }

    function releaseAssetTo(uint256 _assetId, address _recipient) external override {
        address registrar = registrarOf[_assetId];
        if (reserved[_assetId]) {
            _checkAuth();
            reserved[_assetId] = false;
        } else {
            require(registrarOf[_assetId] != address(0), "AssetRegistry: Invalid asset");
        }
        registrarOf[_assetId] = address(0);
        emit AssetRelease(registrar, _assetId, _recipient);
        IAssetRegistrar(registrar).releaseTo(_assetId, _recipient);
    }

    function reserve(uint256 _assetId) external override {
        _checkAuth();
        require(registrarOf[_assetId] != address(0), "AssetRegistry: Invalid asset");
        require(!reserved[_assetId], "AssetRegistry: Already reserved");
        reserved[_assetId] = true;
        emit Reserved(_assetId);
    }

    function _checkAuth() internal view {
        require(msg.sender == loanTracker, "AssetRegistry: Not LoanTracker");
    }
}
