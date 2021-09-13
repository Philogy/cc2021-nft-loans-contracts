// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/ILoanRightsRegistry.sol";

contract LoanRightsRegistry is ERC721, ILoanRightsRegistry {
    mapping(uint256 => uint256) public override loanIdOf;
    mapping(uint256 => address) public override trackerOf;
    mapping(address => mapping(uint256 => uint256)) public override primaryTokenIdOf;
    uint256 public totalTokensIssued;

    constructor() ERC721("Loan Rights Registry", "LRR") { }

    function register(uint256 _loanId, address _lender, address _borrower)
        external override
    {
        uint256 primaryTokenId = totalTokensIssued;
        loanIdOf[primaryTokenId] = _loanId;
        trackerOf[primaryTokenId] = msg.sender;
        primaryTokenIdOf[msg.sender][_loanId] = primaryTokenId;
        _safeMint(_lender, primaryTokenId);
        unchecked {
            _safeMint(_borrower, primaryTokenId + 1);
            totalTokensIssued = primaryTokenId + 2;
        }
        emit Registered(msg.sender, _loanId, primaryTokenId, _lender, _borrower);
    }

    function isLenderOf(uint256 _loanId, address _lender)
        external override view returns (bool)
    {
        uint256 primaryTokenId = primaryTokenIdOf[msg.sender][_loanId];
        return _isApprovedOrOwner(_lender, primaryTokenId);
    }

    function isBorrowerOf(uint256 _loanId, address _borrower)
        external override view returns (bool)
    {
        uint256 primaryTokenId = primaryTokenIdOf[msg.sender][_loanId];
        unchecked {
            return _isApprovedOrOwner(_borrower, primaryTokenId + 1);
        }
    }
}
