// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

interface IAssetRegistry {
    event Registration( uint256 indexed assetId, address indexed registrar);
    event AssetRelease(
        uint256 indexed assetId,
        address indexed registrar,
        address indexed recipient
    );
    event Reserved(uint256 indexed assetId);

    function registerAsset() external returns (uint256);
    function reserve(uint256 _assetId) external;
    function releaseAssetTo(uint256 _assetId, address _recipient) external;
    function totalAssets() external view returns (uint256);
    function registrarOf(uint256 _assetId) external view returns (address);
    function reserved(uint256 _assetId) external view returns (bool);
}
