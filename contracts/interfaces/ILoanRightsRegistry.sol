// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

interface ILoanRightsRegistry {

    event Registered(
        address indexed tracker,
        uint256 indexed loanId,
        uint256 indexed primaryTokenId,
        address initialLender,
        address initialBorrower
    );

    function register(uint256 _loanId, address _lender, address _borrower) external;

    function loanIdOf(uint256 _tokenId) external view returns (uint256);
    function trackerOf(uint256 _tokenId) external view returns (address);
    function primaryTokenIdOf(address _tracker, uint256 _loanId)
        external view returns (uint256);
    function isLenderOf(uint256 _loanId, address _lender)
        external view returns (bool);
    function isBorrowerOf(uint256 _loanId, address _borrower)
        external view returns (bool);
}
