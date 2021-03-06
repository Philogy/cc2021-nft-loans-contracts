// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IWeth.sol";
import "./LoanManagerCore.sol";

abstract contract LoanManagerBorrowLend is LoanManagerCore {
    using SafeERC20 for IERC20;
    using SafeERC20 for IWeth;
    using ECDSA for bytes32;
    using Address for address payable;

    IWeth internal immutable weth;

    bytes32 internal DS_BORROW_NATIVE;
    bytes32 internal DS_BORROW_ERC20;
    bytes32 internal DS_LEND_ERC20;

    mapping(address => mapping(bytes32 => bool)) public markedUnusable;

    constructor(
        address _loanTracker,
        address _rightsRegistry,
        address _assetRegistry,
        address _nftRegistrar,
        address _weth
    )
        LoanManagerCore(
            _loanTracker,
            _rightsRegistry,
            _assetRegistry,
            _nftRegistrar
        )
    {
        weth = IWeth(_weth);

        bytes32 LOCAL_DS = keccak256(abi.encode(
            block.chainid,
            address(this),
            "collateral=ERC721"
        ));

        DS_BORROW_NATIVE = keccak256(abi.encode(
            LOCAL_DS,
            // keccak256("crispy-finance.loan.manager.permit.borrow.native")
            0x2fe0f887857b787fba8694f110978f70777c7e12b63edb93f7e8ec918071450e
        ));
        DS_BORROW_ERC20 = keccak256(abi.encode(
            LOCAL_DS,
            // keccak256("crispy-finance.loan.manager.permit.borrow.erc20")
            0x725ab142179138d77afea6dc169d441b3d1d967575095587d8b1865d1540b3af
        ));
        DS_LEND_ERC20 = keccak256(abi.encode(
            LOCAL_DS,
            // keccak256("crispy-finance.loan.manager.permit.lend.erc20")
            0x9bedf64cceca3a0a5d89d6f6c84e1d6081f45162656fb2f5b09df3334dcf25e9
        ));
    }

    receive() external payable {}

    function markeUnusable(bytes32 _messageHash) external {
        markedUnusable[msg.sender][_messageHash] = true;
    }

    function lendNative(
        IERC721 _collection,
        uint256 _tokenId,
        uint256 _loanTotal,
        IERC20 _debtToken,
        uint256[6] memory _loanParams,
        address _borrower,
        uint256 _expiry,
        bytes memory _borrowerSignature,
        uint256 _msgValue
    ) external payable {
        require(_expiry > block.timestamp, "LoanManager: Signature expired");
        _checkValue(_msgValue);
        require(_msgValue <= _loanTotal, "LoanManager: Payment overload");
        bytes32 messageHash = keccak256(abi.encode(
            DS_BORROW_NATIVE,
            _collection,
            _tokenId,
            _loanTotal,
            _debtToken,
            _loanParams,
            _expiry
        ));
        require(!markedUnusable[_borrower][messageHash], "LoanManager: Unusable");
        _verifySig(messageHash, _borrowerSignature, _borrower);
        uint256 tokenRemainder = _loanTotal - _msgValue;
        if (tokenRemainder > 0) {
            weth.safeTransferFrom(msg.sender, address(this), tokenRemainder);
            weth.withdraw(tokenRemainder);
        }
        payable(_borrower).sendValue(_loanTotal);
        _initNftLoan(
            _collection,
            _tokenId,
            _debtToken,
            _loanParams,
            msg.sender,
            _borrower
        );
    }

    function lendERC20(
        IERC721 _collection,
        uint256 _tokenId,
        IERC20 _loanToken,
        uint256 _loanTotal,
        IERC20 _debtToken,
        uint256[6] memory _loanParams,
        address _borrower,
        uint256 _expiry,
        bytes memory _borrowerSignature,
        uint256 _msgValue
    ) external payable {
        require(_expiry > block.timestamp, "LoanManager: Signature expired");
        _checkValue(_msgValue);
        require(
            _msgValue == 0 ||
            (_loanToken == weth && _msgValue <= _loanTotal),
            "LoanManager: Not wrapped native"
       );
        bytes32 messageHash = keccak256(abi.encode(
            DS_BORROW_ERC20,
            _collection,
            _tokenId,
            _loanToken,
            _loanTotal,
            _debtToken,
            _loanParams,
            _expiry
        ));
        require(!markedUnusable[_borrower][messageHash], "LoanManager: Unusable");
        _verifySig(messageHash, _borrowerSignature, _borrower);
        if (_msgValue > 0) {
            uint256 tokenRemainder = _loanTotal - _msgValue;
            weth.deposit{ value: _msgValue }();
            weth.safeTransfer(_borrower, _msgValue);
            if (tokenRemainder > 0) {
                _loanToken.safeTransferFrom(msg.sender, _borrower, tokenRemainder);
            }
        } else {
            _loanToken.safeTransferFrom(msg.sender, _borrower, _loanTotal);
        }
        _initNftLoan(
            _collection,
            _tokenId,
            _debtToken,
            _loanParams,
            msg.sender,
            _borrower
        );
    }

    function borrow(
        IERC721 _collection,
        uint256 _tokenId,
        IERC20 _loanToken,
        uint256 _loanTotal,
        IERC20 _debtToken,
        uint256[6] memory _loanParams,
        address _lender,
        uint256 _expiry,
        bytes memory _lenderSignature
    ) external payable {
        require(_expiry > block.timestamp, "LoanManager: Signature expired");
        bool receiveNative = address(_loanToken) == address(0);
        if (receiveNative) _loanToken = weth;
        bytes32 messageHash = keccak256(abi.encode(
            DS_LEND_ERC20,
            _collection,
            _tokenId,
            _loanToken,
            _loanTotal,
            _debtToken,
            _loanParams,
            _expiry
        ));
        require(!markedUnusable[_lender][messageHash], "LoanManager: Unusable");
        _verifySig(messageHash, _lenderSignature, _lender);
        if (receiveNative) {
            weth.safeTransferFrom(_lender, address(this), _loanTotal);
            weth.withdraw(_loanTotal);
            payable(msg.sender).sendValue(_loanTotal);
        } else {
            _loanToken.safeTransferFrom(_lender, msg.sender, _loanTotal);
        }
        _initNftLoan(
            _collection,
            _tokenId,
            _debtToken,
            _loanParams,
            _lender,
            msg.sender
        );
    }

    function getDomainSeparators() external view returns (
        bytes32 BORROW_NATIVE,
        bytes32 BORROW_ERC20,
        bytes32 LEND_ERC20
    ) {
        BORROW_NATIVE = DS_BORROW_NATIVE;
        BORROW_ERC20 = DS_BORROW_ERC20;
        LEND_ERC20 = LEND_ERC20;
    }

    function _initNftLoan(
        IERC721 _collection,
        uint256 _tokenId,
        IERC20 _debtToken,
        uint256[6] memory _loanParams,
        address _lender,
        address _borrower
    ) internal {
        uint256 nextAssetId = assetRegistry.totalAssets();
        _collection.safeTransferFrom(_borrower, nftRegistrar, _tokenId);
        loanTracker.createLoan(
            nextAssetId,
            _debtToken,
            _loanParams[0], // uint256 duration
            _loanParams[1], // uint256 eraDuration
            _loanParams[2], // uint256 interestRate
            _loanParams[3], // uint256 startTime
            _loanParams[4], // uint256 initialDebt
            _loanParams[5], // uint256 minPayment
            _lender,
            _borrower
        );
    }

    function _verifySig(
        bytes32 _messageHash,
        bytes memory _sig,
        address _expectedSigner
    ) internal pure {
        require(
            _messageHash
                .toEthSignedMessageHash()
                .recover(_sig) == _expectedSigner,
            "LoanManager: Invalid signature"
        );
    }
}
