// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Address} from "openzeppelin-contracts/utils/Address.sol";

import {Rails} from "../../Rails.sol";
import {Ownable, Ownable} from "../../access/ownable/Ownable.sol";
import {Access} from "../../access/Access.sol";
import {ERC1155} from "./ERC1155.sol";
import {TokenMetadata} from "../TokenMetadata/TokenMetadata.sol";
import {
    ITokenURIExtension, IContractURIExtension
} from "../../extension/examples/metadataRouter/IMetadataExtensions.sol";
import {Operations} from "../../lib/Operations.sol";
import {PermissionsStorage} from "../../access/permissions/PermissionsStorage.sol";
import {IERC1155Rails} from "./interface/IERC1155Rails.sol";
import {Initializable} from "../../lib/initializable/Initializable.sol";
import {ERC1155Storage} from "./ERC1155Storage.sol";

/// @notice This contract implements the Rails pattern to provide enhanced functionality for ERC1155 tokens.
contract ERC1155Rails is Rails, Ownable, Initializable, TokenMetadata, ERC1155, IERC1155Rails {
    /// @notice Declaring this contract `Initializable()` invokes `_disableInitializers()`,
    /// in order to preemptively mitigate proxy privilege escalation attack vectors
    constructor() Initializable() {}

    /// @dev Owner address is implemented using the `Ownable` contract's function
    function owner() public view override(Access, Ownable) returns (address) {
        return Ownable.owner();
    }

    /// @notice Cannot call initialize within a proxy constructor, only post-deployment in a factory
    /// @inheritdoc IERC1155Rails
    function initialize(address owner_, string calldata name_, string calldata symbol_, bytes calldata initData, address forwarder_)
        external
        initializer
    {
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
            _transferOwnership(_msgSender());
            Address.functionDelegateCall(address(this), initData);
            // if sender and owner arg are different, transfer ownership to desired address
            if (_msgSender() != owner_) {
                _transferOwnership(owner_);
            }
        } else {
            _transferOwnership(owner_);
        }
    }

    /*==============
        METADATA
    ==============*/

    /// @dev Function to return the name of a token implementation
    /// @return _ The returned ERC1155 name string
    function name() public view override(ERC1155, TokenMetadata) returns (string memory) {
        return TokenMetadata.name();
    }

    /// @dev Function to return the symbol of a token implementation
    /// @return _ The returned ERC1155 symbol string
    function symbol() public view override(ERC1155, TokenMetadata) returns (string memory) {
        return TokenMetadata.symbol();
    }

    /// @inheritdoc Rails
    function supportsInterface(bytes4 interfaceId) public view override(Rails, ERC1155) returns (bool) {
        return Rails.supportsInterface(interfaceId) || ERC1155.supportsInterface(interfaceId);
    }

    /// @notice Contracts inheriting ERC1155 are required to implement `uri()`
    /// @dev Function to return the ERC1155 uri using extended tokenURI logic
    /// from the `TokenURIExtension` contract
    /// @param tokenId The token ID for which to query a URI
    /// @return _ The returned tokenURI string
    function uri(uint256 tokenId) public view override returns (string memory) {
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

    /// @inheritdoc IERC1155Rails
    function mintTo(address recipient, uint256 tokenId, uint256 value) external onlyPermission(Operations.MINT) {
        _mint(recipient, tokenId, value, "");
    }

    /// @inheritdoc IERC1155Rails
    function burnFrom(address from, uint256 tokenId, uint256 value) external {
        if (!hasPermission(Operations.BURN, _msgSender())) {
            _checkCanTransfer(from);
        }
        _burn(from, tokenId, value);
    }

    /// @dev Overridden to support ERC2771 meta transactions
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /// @dev Overridden to support ERC2771 meta transactions
    function _updateWithAcceptanceCheck(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal virtual override {
        _update(from, to, ids, values);
        if (to != address(0)) {
            address operator = _msgSender();
            if (ids.length == 1) {
                uint256 id = ids[0];
                uint256 value = values[0];
                _doSafeTransferAcceptanceCheck(operator, from, to, id, value, data);
            } else {
                _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, values, data);
            }
        }
    }

    /// @dev Overridden to support ERC2771 meta transactions
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values) internal virtual override {
        if (ids.length != values.length) {
            revert ERC1155InvalidArrayLength(ids.length, values.length);
        }
        ERC1155Storage.Layout storage layout = ERC1155Storage.layout();

        // check before
        (address guard, bytes memory beforeCheckData) = _beforeTokenTransfers(from, to, ids, values);

        address operator = _msgSender();

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 value = values[i];

            if (from != address(0)) {
                uint256 fromBalance = layout.balances[id][from];
                if (fromBalance < value) {
                    revert ERC1155InsufficientBalance(from, fromBalance, value, id);
                }
                layout.balances[id][from] = fromBalance - value;
            } else {
                // increase total supply if minting
                layout.totalSupply[id] += value;
            }

            if (to != address(0)) {
                layout.balances[id][to] += value;
            } else {
                // decrease total supply if burning
                layout.totalSupply[id] -= value;
            }
        }

        if (ids.length == 1) {
            uint256 id = ids[0];
            uint256 value = values[0];
            emit TransferSingle(operator, from, to, id, value);
        } else {
            emit TransferBatch(operator, from, to, ids, values);
        }

        // check after
        _afterTokenTransfers(guard, beforeCheckData);
    }

    /*===========
        GUARD
    ===========*/

    /// @dev Hook called before token transfers. Calls into the given guard.
    /// Provides one of three token operations and its accompanying data to the guard.
    function _beforeTokenTransfers(address from, address to, uint256[] memory ids, uint256[] memory values)
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
        bytes memory data = abi.encode(_msgSender(), from, to, ids, values);

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
    function _checkCanTransfer(address from) internal virtual override {
        if (!hasPermission(Operations.TRANSFER, _msgSender())) {
            if (from != _msgSender() && !isApprovedForAll(from, _msgSender())) {
                revert ERC1155MissingApprovalForAll(_msgSender(), from);
            }
        }
    }

    /// @dev Restrict Permissions write access to the `Operations.PERMISSIONS` permission
    function _checkCanUpdatePermissions() internal view override {
        _checkPermission(Operations.PERMISSIONS, _msgSender());
    }

    /// @dev Restrict Guards write access to the `Operations.GUARDS` permission
    function _checkCanUpdateGuards() internal view override {
        _checkPermission(Operations.GUARDS, _msgSender());
    }

    /// @dev Restrict calls via Execute to the `Operations.EXECUTE` permission
    function _checkCanExecuteCall() internal view override {
        _checkPermission(Operations.CALL, _msgSender());
    }

    /// @dev Restrict ERC-165 write access to the `Operations.INTERFACE` permission
    function _checkCanUpdateInterfaces() internal view override {
        _checkPermission(Operations.INTERFACE, _msgSender());
    }

    /// @dev Restrict TokenMetadata write access to the `Operations.METADATA` permission
    function _checkCanUpdateTokenMetadata() internal view override {
        _checkPermission(Operations.METADATA, _msgSender());
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
