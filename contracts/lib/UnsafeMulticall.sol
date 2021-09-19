// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Address.sol";

/// @notice copy of Uniswap's Multicall (github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol)
abstract contract UnsafeMulticall {
    using Address for address payable;

    function skimNativeTo(address payable _recipient) external {
        _recipient.sendValue(_safeMsgValue());
    }

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

    function _checkValue(uint256 _msgValue) internal view {
        require(_msgValue <= _safeMsgValue(), "UMC: Insufficient msg.value");
    }

    function _safeMsgValue() internal view returns (uint256) {
        return address(this).balance - _storedNative();
    }

    function _storedNative() internal virtual view returns (uint256);
}
