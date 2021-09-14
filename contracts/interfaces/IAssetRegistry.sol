// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

interface IAssetRegistry {
    function registerAsset() external returns (uint256);
    function releaseAssetTo(uint256 _assetId, address _recipient) external;
    function totalAssets() external view returns (uint256);
    function assetRegistrarOf(uint256 _assetId) external view returns (address);
    function isValidAsset(uint256 _assetId) external view returns (bool);
}
