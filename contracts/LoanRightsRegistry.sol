// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/ILoanRightsRegistry.sol";

contract LoanRightsRegistry is ERC721, ILoanRightsRegistry {
    address internal immutable loanTracker;
    uint256 public totalTokensIssued;

    constructor(address _loanTracker) ERC721("Loan Rights Registry", "LRR") {
        loanTracker = _loanTracker;
    }

    function register(address _lender, address _borrower)
        external override
    {
        require(msg.sender == loanTracker, "LLR: Not LoanTracker");
        uint256 primaryTokenId = totalTokensIssued;
        _safeMint(_lender, primaryTokenId);
        _safeMint(_borrower, primaryTokenId + 1);
        totalTokensIssued = primaryTokenId + 2;
        emit Registered(primaryTokenId, _lender, _borrower);
    }

    function deleteBorrower(uint256 _loanId) external override {
        require(msg.sender == loanTracker, "LLR: Not LoanTracker");
        uint256 borrowerTokenId = _loanId * 2 + 1;
        _burn(borrowerTokenId);
    }

    function lenderOf(uint256 _loanId)
        external override view returns (address)
    {
        return ownerOf(_loanId * 2);
    }

    function borrowerOf(uint256 _loanId)
        external override view returns (address)
    {
        return ownerOf(_loanId * 2 + 1);
    }

    function isLenderOf(uint256 _loanId, address _lender)
        external override view returns (bool)
    {
        uint256 primaryTokenId = _loanId * 2;
        return _isApprovedOrOwner(_lender, primaryTokenId);
    }

    function isBorrowerOf(uint256 _loanId, address _borrower)
        external override view returns (bool)
    {
        uint256 primaryTokenId = _loanId * 2;
        unchecked {
            return _isApprovedOrOwner(_borrower, primaryTokenId + 1);
        }
    }
}
