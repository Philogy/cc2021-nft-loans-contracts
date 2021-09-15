// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "../interfaces/IAssetRegistrar.sol";
import "../interfaces/IAssetRegistry.sol";

contract MockAssetRegistrar is IAssetRegistrar {
    IAssetRegistry public registry;

    event NewAssetId(uint256 newAssetId);
    event ReleaseHook(uint256 assetId, address recipient);

    constructor(address _registry) {
        registry = IAssetRegistry(_registry);
    }

    function registerAsset() external {
        uint256 newAssetId = registry.registerAsset();
        emit NewAssetId(newAssetId);
    }

    function releaseTo(uint256 _assetId, address _recipient)
        external override
    {
        require(msg.sender == address(registry), "Not Registry");
        emit ReleaseHook(_assetId, _recipient);
    }
}
