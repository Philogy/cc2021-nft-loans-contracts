// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ILoanRightsRegistry is IERC721 {

    event Registered(
        uint256 indexed loanId,
        address indexed initialLender,
        address indexed initialBorrower
    );
    event ManagerApproval(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function register(address _lender, address _borrower) external;
    function deleteBorrowerOf(uint256 _loanId) external;
    function deleteLenderOf(uint256 _loanId) external;
    function lenderOf(uint256 _loanId) external view returns (address);
    function setDualApproval(address _operator, bool _approved) external;
    function setIsManager(address _operator, bool _approved) external;
    function isManagerOf(address _owner, address _operator)
        external view returns (bool);
    function borrowerOf(uint256 _loanId) external view returns (address);
    function isLenderOf(uint256 _loanId, address _lender)
        external view returns (bool);
    function isBorrowerOf(uint256 _loanId, address _borrower)
        external view returns (bool);
}
