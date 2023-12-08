// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Address} from "openzeppelin-contracts/utils/Address.sol";

import {Rails} from "../../Rails.sol";
import {Ownable, Ownable} from "../../access/ownable/Ownable.sol";
import {Access} from "../../access/Access.sol";
import {ERC721} from "./ERC721.sol";
import {IERC721} from "./interface/IERC721.sol";
import {TokenMetadata} from "../TokenMetadata/TokenMetadata.sol";
import {
    ITokenURIExtension, IContractURIExtension
} from "../../extension/examples/metadataRouter/IMetadataExtensions.sol";
import {Operations} from "../../lib/Operations.sol";
import {PermissionsStorage} from "../../access/permissions/PermissionsStorage.sol";
import {IERC721Rails} from "./interface/IERC721Rails.sol";
import {Initializable} from "../../lib/initializable/Initializable.sol";

/// @notice This contract implements the Rails pattern to provide enhanced functionality for ERC721 tokens.
/// @dev ERC721A chosen for only practical solution for large token supply allocations
contract ERC721Rails is Rails, Ownable, Initializable, TokenMetadata, ERC721, IERC721Rails {
    /// @notice Declaring this contract `Initializable()` invokes `_disableInitializers()`,
    /// in order to preemptively mitigate proxy privilege escalation attack vectors
    constructor() Initializable() {}

    /// @dev Owner address is implemented using the `Ownable` contract's function
    function owner() public view override(Access, Ownable) returns (address) {
        return Ownable.owner();
    }

    /// @notice Cannot call initialize within a proxy constructor, only post-deployment in a factory
    /// @inheritdoc IERC721Rails
    function initialize(address owner_, string calldata name_, string calldata symbol_, bytes calldata initData, address forwarder_)
        external
        initializer
    {
        ERC721._initialize();
        _setName(name_);
        _setSymbol(symbol_);
        _forwarderInitializer(forwarder_);
        if (initData.length > 0) {
            /// @dev if called within a constructor, self-delegatecall will not work because this address does not yet have
            /// bytecode implementing the init functions -> revert here with nicer error message
            if (address(this).code.length == 0) {
                revert CannotInitializeWhileConstructing();
            }
            // make msg.sender the owner to ensure they have all permissions for further initialization
            _transferOwnership(msg.sender);
            Address.functionDelegateCall(address(this), initData);
            // if sender and owner arg are different, transfer ownership to desired address
            if (msg.sender != owner_) {
                _transferOwnership(owner_);
            }
        } else {
            _transferOwnership(owner_);
        }
    }

    /// @dev Override starting tokenId exposed by ERC721A, which is 0 by default
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /*==============
        METADATA
    ==============*/

    /// @inheritdoc Rails
    function supportsInterface(bytes4 interfaceId) public view override(Rails, ERC721) returns (bool) {
        return Rails.supportsInterface(interfaceId) || ERC721.supportsInterface(interfaceId);
    }

    /// @dev Function to return the name of a token implementation
    /// @return _ The returned ERC721 name string
    function name() public view override(IERC721, TokenMetadata) returns (string memory) {
        return TokenMetadata.name();
    }

    /// @dev Function to return the symbol of a token implementation
    /// @return _ The returned ERC721 symbol string
    function symbol() public view override(IERC721, TokenMetadata) returns (string memory) {
        return TokenMetadata.symbol();
    }

    /// @notice Contracts inheriting ERC721A are required to implement `tokenURI()`
    /// @dev Function to return the ERC721 tokenURI using extended URI logic
    /// from the `TokenURIExtension` contract
    /// @param tokenId The token ID for which to query a URI
    /// @return _ The returned tokenURI string
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // to avoid clashing selectors, use standardized `ext_` prefix
        return ITokenURIExtension(address(this)).ext_tokenURI(tokenId);
    }

    /// @dev Returns the contract URI for this ERC20 token, a modern standard for NFTs
    /// @notice Uses extended contract URI logic from the `ContractURIExtension` contract
    /// @return _ The returned contractURI string
    function contractURI() public view override returns (string memory) {
        // to avoid clashing selectors, use standardized `ext_` prefix
        return IContractURIExtension(address(this)).ext_contractURI();
    }

    /*=============
        SETTERS
    =============*/

    /// @inheritdoc IERC721Rails
    function mintTo(address recipient, uint256 quantity)
        external
        onlyPermission(Operations.MINT)
        returns (uint256 mintStartTokenId)
    {
        mintStartTokenId = _nextTokenId();
        _safeMint(recipient, quantity);
    }

    /// @inheritdoc IERC721Rails
    function burn(uint256 tokenId) external {
        if (!hasPermission(Operations.BURN, msg.sender)) {
            _checkCanTransfer(ownerOf(tokenId), tokenId);
            /// @todo resolve gas inefficiency of reading ownerOf twice
        }
        _burn(tokenId);
    }

    /*===========
        GUARD
    ===========*/

    /// @dev Hook called before token transfers. Calls into the given guard.
    /// Provides one of three token operations and its accompanying data to the guard.
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        view
        override
        returns (address guard, bytes memory beforeCheckData)
    {
        bytes8 operation;
        if (from == address(0)) {
            operation = Operations.MINT;
        } else if (to == address(0)) {
            operation = Operations.BURN;
        } else {
            operation = Operations.TRANSFER;
        }
        bytes memory data = abi.encode(msg.sender, from, to, startTokenId, quantity);

        return checkGuardBefore(operation, data);
    }

    /// @dev Hook called after token transfers. Calls into the given guard.
    function _afterTokenTransfers(address guard, bytes memory checkBeforeData) internal view override {
        checkGuardAfter(guard, checkBeforeData, ""); // no execution data
    }

    /*===================
        AUTHORIZATION
    ===================*/

    /// @dev Check for `Operations.TRANSFER` permission before ownership and approval
    function _checkCanTransfer(address account, uint256 tokenId) internal virtual override {
        if (!hasPermission(Operations.TRANSFER, msg.sender)) {
            super._checkCanTransfer(account, tokenId);
        }
    }

    /// @dev Restrict Permissions write access to the `Operations.PERMISSIONS` permission
    function _checkCanUpdatePermissions() internal view override {
        _checkPermission(Operations.PERMISSIONS, msg.sender);
    }

    /// @dev Restrict Guards write access to the `Operations.GUARDS` permission
    function _checkCanUpdateGuards() internal view override {
        _checkPermission(Operations.GUARDS, msg.sender);
    }

    /// @dev Restrict calls via Execute to the `Operations.EXECUTE` permission
    function _checkCanExecuteCall() internal view override {
        _checkPermission(Operations.CALL, msg.sender);
    }

    /// @dev Restrict ERC-165 write access to the `Operations.INTERFACE` permission
    function _checkCanUpdateInterfaces() internal view override {
        _checkPermission(Operations.INTERFACE, msg.sender);
    }

    /// @dev Restrict TokenMetadata write access to the `Operations.METADATA` permission
    function _checkCanUpdateTokenMetadata() internal view override {
        _checkPermission(Operations.METADATA, msg.sender);
    }

    /// @dev Only the `owner` possesses Extensions write access
    function _checkCanUpdateExtensions() internal view override {
        // changes to core functionality must be restricted to owners to protect admins overthrowing
        _checkOwner();
    }

    /// @dev Only the `owner` possesses UUPS upgrade rights
    function _authorizeUpgrade(address) internal view override {
        // changes to core functionality must be restricted to owners to protect admins overthrowing
        _checkOwner();
    }
}
