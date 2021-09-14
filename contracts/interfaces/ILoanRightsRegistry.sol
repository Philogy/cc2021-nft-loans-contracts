// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ILoanRightsRegistry is IERC721 {

    event Registered(
        uint256 indexed primaryTokenId,
        address indexed initialLender,
        address indexed initialBorrower
    );

    function register(address _lender, address _borrower) external;
    function deleteBorrower(uint256 _loanId) external;
    function deleteLender(uint256 _loanId) external;
    function lenderOf(uint256 _loanId) external view returns (address);
    function borrowerOf(uint256 _loanId) external view returns (address);
    function isLenderOf(uint256 _loanId, address _lender)
        external view returns (bool);
    function isBorrowerOf(uint256 _loanId, address _borrower)
        external view returns (bool);
}
