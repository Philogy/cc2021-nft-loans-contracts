// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "./interfaces/IAssetRegistry.sol";
import "./interfaces/IAssetRegistrar.sol";

contract AssetRegistry is IAssetRegistry {
    address internal immutable loanTracker;
    uint256 public override totalAssets;
    mapping(uint256 => address) public override registrarOf;
    mapping(uint256 => bool) public override claimed;

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
        _checkAuth();
        address registrar = registrarOf[_assetId];
        registrarOf[_assetId] = address(0);
        claimed[_assetId] = false;
        emit AssetRelease(registrar, _assetId, _recipient);
        IAssetRegistrar(registrar).releaseTo(_assetId, _recipient);
    }

    function tryClaim(uint256 _assetId) external override {
        _checkAuth();
        require(!claimed[_assetId], "AssetRegistry: Already claimed");
        claimed[_assetId] = true;
    }

    function _checkAuth() internal view {
        require(msg.sender == loanTracker, "AssetRegistry: Not LoanTracker");
    }
}
