// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../interfaces/ILoanRightsRegistry.sol";

contract LoanRightsRegistry is ERC721, ILoanRightsRegistry {
    address internal immutable loanTracker;
    uint256 public totalTokensIssued;
    mapping(address => mapping(address => bool)) public override isManagerOf;

    constructor(address _loanTracker) ERC721("Loan Rights Registry", "LRR") {
        loanTracker = _loanTracker;
    }

    function register(address _lender, address _borrower)
        external override
    {
        _checkOnlyLoanTracker();
        uint256 primaryTokenId = totalTokensIssued;
        _safeMint(_lender, primaryTokenId);
        _safeMint(_borrower, primaryTokenId + 1);
        totalTokensIssued = primaryTokenId + 2;
        emit Registered(primaryTokenId / 2, _lender, _borrower);
    }

    function deleteBorrowerOf(uint256 _loanId) external override {
        _checkOnlyLoanTracker();
        uint256 borrowerTokenId = _loanId * 2 + 1;
        _burn(borrowerTokenId);
    }

    function deleteLenderOf(uint256 _loanId) external override {
        _checkOnlyLoanTracker();
        uint256 primaryTokenId = _loanId * 2;
        _burn(primaryTokenId);
    }

    function setManagerApproval(address _operator, bool _approved)
        external override
    {
        isManagerOf[msg.sender][_operator] = _approved;
        emit ManagerApproval(msg.sender, _operator, _approved);
        setApprovalForAll(_operator, _approved);
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
        return _isManagerOrOwner(_lender, primaryTokenId);
    }

    function isBorrowerOf(uint256 _loanId, address _borrower)
        external override view returns (bool)
    {
        uint256 primaryTokenId = _loanId * 2;
        return _isManagerOrOwner(_borrower, primaryTokenId + 1);
    }

    function _isManagerOrOwner(address _operator, uint256 _tokenId)
        internal view returns (bool)
    {
        address owner = ownerOf(_tokenId);
        return owner == _operator || isManagerOf[owner][_operator];
    }

    function _checkOnlyLoanTracker() internal view {
        require(msg.sender == loanTracker, "LLR: Not LoanTracker");
    }
}
