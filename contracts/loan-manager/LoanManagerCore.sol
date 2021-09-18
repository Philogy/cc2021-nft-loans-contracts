// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "../interfaces/ILoanTracker.sol";
import "../interfaces/ILoanRightsRegistry.sol";
import "../interfaces/IAssetRegistry.sol";

contract LoanManagerCore {
    ILoanTracker internal immutable loanTracker;
    ILoanRightsRegistry internal immutable rightsRegistry;
    IAssetRegistry internal immutable assetRegistry;
    address internal immutable nftRegistrar;

    constructor(
        address _loanTracker,
        address _rightsRegistry,
        address _assetRegistry,
        address _nftRegistrar
    ) {
        loanTracker = ILoanTracker(_loanTracker);
        rightsRegistry = ILoanRightsRegistry(_rightsRegistry);
        assetRegistry = IAssetRegistry(_assetRegistry);
        nftRegistrar = _nftRegistrar;
    }
}
