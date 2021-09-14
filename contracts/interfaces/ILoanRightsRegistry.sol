// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

interface ILoanRightsRegistry {

    event Registered(
        uint256 indexed primaryTokenId,
        address indexed initialLender,
        address indexed initialBorrower
    );

    function register(address _lender, address _borrower) external;
    function deleteBorrower(uint256 _loanId) external;
    function isLenderOf(uint256 _loanId, address _lender)
        external view returns (bool);
    function isBorrowerOf(uint256 _loanId, address _borrower)
        external view returns (bool);
}
