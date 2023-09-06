// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Address} from "openzeppelin-contracts/utils/Address.sol";

import {Mage} from "../../Mage.sol";
import {Ownable, OwnableInternal} from "../../access/ownable/Ownable.sol";
import {Access} from "../../access/Access.sol";
import {ERC20} from "./ERC20.sol";
import {IERC20} from "./interface/IERC20.sol";
import {TokenMetadata} from "../TokenMetadata/TokenMetadata.sol";
import {TokenMetadataInternal} from "../TokenMetadata/TokenMetadataInternal.sol";
import {
    ITokenURIExtension, IContractURIExtension
} from "../../extension/examples/metadataRouter/IMetadataExtensions.sol";
import {Operations} from "../../lib/Operations.sol";
import {PermissionsStorage} from "../../access/permissions/PermissionsStorage.sol";
import {IERC20Mage} from "./interface/IERC20Mage.sol";
import {Initializable} from "../../lib/initializable/Initializable.sol";

/// @notice apply Mage pattern to ERC20s
contract ERC20Mage is Mage, Ownable, Initializable, TokenMetadata, ERC20, IERC20Mage {

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

    /*==============
        METADATA
    ==============*/

    function name() public view override(IERC20, TokenMetadataInternal) returns (string memory) {
        return TokenMetadataInternal.name();
    }

    function symbol() public view override(IERC20, TokenMetadataInternal) returns (string memory) {
        return TokenMetadataInternal.symbol();
    }

    // include contractURI as modern standard for NFTs
    function contractURI() public view override returns (string memory) {
        // to avoid clashing selectors, use standardized `ext_` prefix
        return IContractURIExtension(address(this)).ext_contractURI();
    }

    /*=============
        SETTERS
    =============*/

    function mintTo(address recipient, uint256 amount) external onlyPermission(Operations.MINT) returns (bool) {
        _mint(recipient, amount);
        return true;
    }

    /// @dev rework allowance to also allow permissioned users burn unconditionally
    function burnFrom(address from, uint256 amount) external returns(bool) {
        if (!hasPermission(Operations.BURN, msg.sender)) {
            _spendAllowance(from, msg.sender, amount);
        }
        _burn(from, amount);
        return true;
    }

    /*===========
        GUARD
    ===========*/

    function _beforeTokenTransfer(address from, address to, uint256 amount)
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
        bytes memory data = abi.encode(msg.sender, from, to, amount);

        return checkGuardBefore(operation, data);
    }

    function _afterTokenTransfer(address guard, bytes memory checkBeforeData) internal view override {
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
        _checkPermission(Operations.EXECUTE, msg.sender);
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
