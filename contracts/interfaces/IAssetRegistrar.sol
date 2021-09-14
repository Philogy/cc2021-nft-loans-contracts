// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

interface IAssetRegistrar {
    function releaseTo(uint256 _assetSubId, address _recipient) external;
}
