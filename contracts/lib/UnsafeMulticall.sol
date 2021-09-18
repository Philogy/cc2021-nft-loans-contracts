// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

/// @notice copy of Uniswap's Multicall (github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol)
abstract contract UnsafeMulticall {
    function multicall(bytes[] calldata data)
        external payable returns (bytes[] memory results)
    {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }
            results[i] = result;
        }
    }
}
