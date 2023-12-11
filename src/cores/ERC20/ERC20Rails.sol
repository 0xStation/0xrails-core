// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {Rails} from "../../Rails.sol";
import {Ownable, Ownable} from "../../access/ownable/Ownable.sol";
import {Access} from "../../access/Access.sol";
import {ERC20} from "./ERC20.sol";
import {IERC20} from "./interface/IERC20.sol";
import {TokenMetadata} from "../TokenMetadata/TokenMetadata.sol";
import {
    ITokenURIExtension, IContractURIExtension
} from "../../extension/examples/metadataRouter/IMetadataExtensions.sol";
import {Operations} from "../../lib/Operations.sol";
import {PermissionsStorage} from "../../access/permissions/PermissionsStorage.sol";
import {IERC20Rails} from "./interface/IERC20Rails.sol";
import {Initializable} from "../../lib/initializable/Initializable.sol";

/// @notice This contract implements the Rails pattern to provide enhanced functionality for ERC20 tokens.
contract ERC20Rails is Rails, Ownable, Initializable, TokenMetadata, ERC20, IERC20Rails {
    /// @notice Declaring this contract `Initializable()` invokes `_disableInitializers()`,
    /// in order to preemptively mitigate proxy privilege escalation attack vectors
    constructor() Initializable() {}

    /// @dev Owner address is implemented using the `Ownable` contract's function
    function owner() public view override(Access, Ownable) returns (address) {
        return Ownable.owner();
    }

    /// @dev Initialize the ERC20Rails contract with the given owner, name, symbol, and initialization data.
    /// @notice Cannot call initialize within a proxy constructor, only post-deployment in a factory.
    /// @param owner_ The initial owner of the contract.
    /// @param name_ The name of the ERC20 token.
    /// @param symbol_ The symbol of the ERC20 token.
    /// @param initData The initialization data.
    /// @param forwarder_ The ERC2771 trusted forwarder used to enable gasless meta transactions.
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

    /// @inheritdoc Rails
    function supportsInterface(bytes4 interfaceId) public view override(Rails, ERC20) returns (bool) {
        return Rails.supportsInterface(interfaceId) || ERC20.supportsInterface(interfaceId);
    }

    /// @dev Function to return the name of a token implementation
    /// @return _ The returned ERC20 name string
    function name() public view override(IERC20, TokenMetadata) returns (string memory) {
        return TokenMetadata.name();
    }

    /// @dev Function to return the symbol of a token implementation
    /// @return _ The returned ERC20 symbol string
    function symbol() public view override(IERC20, TokenMetadata) returns (string memory) {
        return TokenMetadata.symbol();
    }

    /// @dev Returns the contract URI for this ERC20 token.
    /// @notice Uses extended contract URI logic from the `ContractURIExtension` contract
    /// @return _ The returned contractURI string
    function contractURI() public view override returns (string memory) {
        // to avoid clashing selectors, use standardized `ext_` prefix
        return IContractURIExtension(address(this)).ext_contractURI();
    }

    /*=============
        SETTERS
    =============*/

    /// @inheritdoc IERC20Rails
    function mintTo(address recipient, uint256 amount) external onlyPermission(Operations.MINT) returns (bool) {
        _mint(recipient, amount);
        return true;
    }

    /// @inheritdoc IERC20Rails
    /// @dev Rework allowance to also allow permissioned users burn unconditionally
    function burnFrom(address from, uint256 amount) external returns (bool) {
        if (!hasPermission(Operations.BURN, _msgSender())) {
            _spendAllowance(from, _msgSender(), amount);
        }
        _burn(from, amount);
        return true;
    }

    /// @dev Overridden to support ERC2771 meta-transactions
    function transfer(address to, uint256 value) public virtual override returns (bool) {
        _transfer(_msgSender(), to, value);
        return true;
    }

    /// @inheritdoc IERC20Rails
    function transferFrom(address from, address to, uint256 value)
        public
        virtual
        override(ERC20, IERC20Rails)
        returns (bool)
    {
        _checkCanTransfer(from, _msgSender(), value);
        _transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public virtual override returns (bool) {
        _approve(_msgSender(), spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
        _approve(_msgSender(), spender, allowance(_msgSender(), spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 requestedDecrease) public virtual override returns (bool) {
        uint256 currentAllowance = allowance(_msgSender(), spender);
        if (currentAllowance < requestedDecrease) {
            revert ERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
        }
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - requestedDecrease);
        }

        return true;
    }

    /*===========
        GUARD
    ===========*/

    /// @dev Hook called before token transfers. Calls into the given guard.
    /// Provides one of three token operations and its accompanying data to the guard.
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
        bytes memory data = abi.encode(_msgSender(), from, to, amount);

        return checkGuardBefore(operation, data);
    }

    /// @dev Hook called after token transfers. Calls into the given guard.
    function _afterTokenTransfer(address guard, bytes memory checkBeforeData) internal view override {
        checkGuardAfter(guard, checkBeforeData, ""); // no execution data
    }

    /*===================
        AUTHORIZATION
    ===================*/

    /// @dev Check for `Operations.TRANSFER` permission before ownership and approval
    /// @notice Slightly different implementation than 721 and 1155 Rails contracts since this function doesn't
    /// already exist as a default virtual one. Wraps `_spendAllowance()` and replaces it in `transferFrom()`
    function _checkCanTransfer(address _owner, address _spender, uint256 _value) internal virtual {
        if (!hasPermission(Operations.TRANSFER, _spender)) {
            _spendAllowance(_owner, _spender, _value);
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
