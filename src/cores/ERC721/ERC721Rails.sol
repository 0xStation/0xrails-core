// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Address} from "openzeppelin-contracts/utils/Address.sol";

import {Rails} from "../../Rails.sol";
import {Ownable, OwnableInternal} from "../../access/ownable/Ownable.sol";
import {Access} from "../../access/Access.sol";
import {ERC721AUpgradeable} from "./ERC721AUpgradeable.sol";
import {ERC721} from "./ERC721.sol";
import {ERC721Internal} from "./ERC721Internal.sol";
import {TokenMetadata} from "../TokenMetadata/TokenMetadata.sol";
import {TokenMetadataInternal} from "../TokenMetadata/TokenMetadataInternal.sol";
import {
    ITokenURIExtension, IContractURIExtension
} from "../../extension/examples/metadataRouter/IMetadataExtensions.sol";
import {Operations} from "../../lib/Operations.sol";
import {PermissionsStorage} from "../../access/permissions/PermissionsStorage.sol";
import {IERC721Rails} from "./interface/IERC721Rails.sol";
import {Initializable} from "../../lib/initializable/Initializable.sol";

/// @notice apply Rails pattern to ERC721 NFTs
/// @dev ERC721A chosen for only practical solution for large token supply allocations
contract ERC721Rails is Rails, Ownable, Initializable, TokenMetadata, ERC721, IERC721Rails {

    constructor() Initializable() {}
    
    // owner stored explicitly
    function owner() public view override(Access, OwnableInternal) returns (address) {
        return OwnableInternal.owner();
    }

    /// @dev cannot call initialize within a proxy constructor, only post-deployment in a factory
    function initialize(address owner_, string calldata name_, string calldata symbol_, bytes calldata initData)
        external
        initializer
    {
        ERC721Internal._initialize();
        _setName(name_);
        _setSymbol(symbol_);
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


    // override starting tokenId exposed by ERC721A
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /*==============
        METADATA
    ==============*/

    function supportsInterface(bytes4 interfaceId) public view override(Rails, ERC721) returns (bool) {
        return Rails.supportsInterface(interfaceId) || ERC721.supportsInterface(interfaceId);
    }

    function name() public view override(ERC721, TokenMetadataInternal) returns (string memory) {
        return TokenMetadataInternal.name();
    }

    function symbol() public view override(ERC721, TokenMetadataInternal) returns (string memory) {
        return TokenMetadataInternal.symbol();
    }

    // must override ERC721A implementation
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // to avoid clashing selectors, use standardized `ext_` prefix
        return ITokenURIExtension(address(this)).ext_tokenURI(tokenId);
    }

    // include contractURI as modern standard for NFTs
    function contractURI() public view override returns (string memory) {
        // to avoid clashing selectors, use standardized `ext_` prefix
        return IContractURIExtension(address(this)).ext_contractURI();
    }

    /*=============
        SETTERS
    =============*/

    function mintTo(address recipient, uint256 quantity) external onlyPermission(Operations.MINT) {
        _safeMint(recipient, quantity);
    }

    function burn(uint256 tokenId) external {
        if (!hasPermission(Operations.BURN, msg.sender)) {
            _checkCanTransfer(ownerOf(tokenId), tokenId); /// @todo resolve gas inefficiency of reading ownerOf twice
        }
        _burn(tokenId);
    }

    /*===========
        GUARD
    ===========*/

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

    function _afterTokenTransfers(address guard, bytes memory checkBeforeData) internal view override {
        checkGuardAfter(guard, checkBeforeData, ""); // no execution data
    }

    /*===================
        AUTHORIZATION
    ===================*/

    function _checkCanUpdatePermissions() internal view override {
        _checkPermission(Operations.PERMISSIONS, msg.sender);
    }

    function _checkCanUpdateGuards() internal view override {
        _checkPermission(Operations.GUARDS, msg.sender);
    }

    function _checkCanExecuteCall() internal view override {
        _checkPermission(Operations.CALL, msg.sender);
    }

    function _checkCanUpdateInterfaces() internal view override {
        _checkPermission(Operations.INTERFACE, msg.sender);
    }

    function _checkCanUpdateTokenMetadata() internal view override {
        _checkPermission(Operations.METADATA, msg.sender);
    }

    // changes to core functionality must be restricted to owners to protect admins overthrowing
    function _checkCanUpdateExtensions() internal view override {
        _checkOwner();
    }

    function _authorizeUpgrade(address) internal view override {
        _checkOwner();
    }
}
