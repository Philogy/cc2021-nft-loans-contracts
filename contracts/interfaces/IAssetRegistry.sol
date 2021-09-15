// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

interface IAssetRegistry {
    event Registration(address indexed registrar, uint256 indexed assetId);
    event AssetRelease(
        address indexed registrar,
        uint256 indexed assetId,
        address indexed recipient
    );

    function registerAsset() external returns (uint256);
    function tryClaim(uint256 _assetId) external;
    function releaseAssetTo(uint256 _assetId, address _recipient) external;
    function totalAssets() external view returns (uint256);
    function registrarOf(uint256 _assetId) external view returns (address);
    function claimed(uint256 _assetId) external view returns (bool);
}
