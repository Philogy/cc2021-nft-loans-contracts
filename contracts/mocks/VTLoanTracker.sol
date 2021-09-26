// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../core/LoanTracker.sol";

contract VTLoanTracker is LoanTracker, Ownable {
    uint256 public vTime;

    constructor(address _assetRegistry, address _rightsRegistry)
        LoanTracker(_assetRegistry, _rightsRegistry)
        Ownable()
    { }

    function increaseVirtualTime(uint256 _increase) external onlyOwner {
        vTime += _increase;
    }

    function setVirtualTime(uint256 _vTime) external onlyOwner {
        vTime = _vTime;
    }

    function _getTimestamp() internal override view returns (uint256) {
        return vTime;
    }
}
