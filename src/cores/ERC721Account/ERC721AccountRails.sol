// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";

import {AccountRails} from "src/cores/account/AccountRails.sol";
import {Account} from "src/cores/account/Account.sol";
import {IEntryPoint} from "src/lib/ERC4337/interface/IEntryPoint.sol";
import {UserOperation} from "src/lib/ERC4337/utils/UserOperation.sol";
import {ValidatorsStorage} from "src/validator/ValidatorsStorage.sol";
import {Initializable} from "src/lib/initializable/Initializable.sol";
import {Access} from "src/access/Access.sol";
import {IPermissions} from "src/access/permissions/interface/IPermissions.sol";
import {Extensions} from "src/extension/Extensions.sol";
import {Operations} from "src/lib/Operations.sol";
import {ERC6551AccountLib} from "src/lib/ERC6551/lib/ERC6551AccountLib.sol";
import {IERC721} from "../ERC721/interface/IERC721.sol";
import {IERC721AccountRails} from "./interface/IERC721AccountRails.sol";
import {ERC6551Account, IERC6551Account} from "src/lib/ERC6551/ERC6551Account.sol";
import {ERC6551AccountStorage} from "src/lib/ERC6551/ERC6551AccountStorage.sol";
import {IERC6551AccountGroup} from "src/lib/ERC6551AccountGroup/interface/IERC6551AccountGroup.sol";

/// @notice An ERC-4337 Account bound to an ERC-721 token via ERC-6551
contract ERC721AccountRails is AccountRails, ERC6551Account, Initializable, IERC721AccountRails {
    /*====================
        INITIALIZATION
    ====================*/

    /// @param _entryPointAddress The contract address for this chain's ERC-4337 EntryPoint contract
    constructor(address _entryPointAddress) Account(_entryPointAddress) Initializable() {}

    /// @inheritdoc IERC721AccountRails
    /// @notice Important that it is assumed the caller of this function is trusted by the Account Group
    function initialize(bytes memory initData) external initializer {
        if (initData.length > 0) {
            // make msg.sender an ADMIN to ensure they have all permissions for further initialization
            _addPermission(Operations.ADMIN, msg.sender);
            Address.functionDelegateCall(address(this), initData);
            // remove sender ADMIN permissions
            _removePermission(Operations.ADMIN, msg.sender);
        }
    }

    receive() external payable override(Extensions, IERC6551Account) {}

    /*==============
        METADATA
    ==============*/

    /// @inheritdoc AccountRails
    function supportsInterface(bytes4 interfaceId) public view override(AccountRails, ERC6551Account) returns (bool) {
        return AccountRails.supportsInterface(interfaceId) || ERC6551Account.supportsInterface(interfaceId);
    }

    /*===============
        OVERRIDES
    ===============*/

    /// @inheritdoc Account
    function withdrawFromEntryPoint(address payable recipient, uint256 amount) public virtual override {
        if (!_isAuthorized(Operations.ADMIN, msg.sender)) {
            revert IPermissions.PermissionDoesNotExist(Operations.ADMIN, msg.sender);
        }

        _updateState();
        IEntryPoint(entryPoint).withdrawTo(recipient, amount);
    }

    function _checkSenderIsEntryPoint() internal virtual override {
        _updateState();
        super._checkSenderIsEntryPoint();
    }

    /// @dev When evaluating signatures that don't contain the `VALIDATOR_FLAG`, authenticate only the owner
    function _defaultValidateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 /*missingAccountFunds*/ )
        internal
        view
        virtual
        override
        returns (bool)
    {
        // recover signer address and any error
        (address signer, ECDSA.RecoverError err) = ECDSA.tryRecover(userOpHash, userOp.signature);
        // return if signature is malformed
        if (err != ECDSA.RecoverError.NoError) return false;

        // return true only if signer is owner, owner-delegated, or AccountGroup admin
        return _isAuthorized(Operations.ADMIN, signer);
    }

    /// @dev When evaluating signatures that don't contain the `VALIDATOR_FLAG`, authenticate only the owner
    function _defaultIsValidSignature(bytes32 hash, bytes memory signature)
        internal
        view
        virtual
        override
        returns (bool)
    {
        // support non-modular signatures by recovering signer address and reverting malleable or invalid signatures
        (address signer, ECDSA.RecoverError err) = ECDSA.tryRecover(hash, signature);
        // return if signature is malformed
        if (err != ECDSA.RecoverError.NoError) return false;

        // return true only if signer is owner, owner-delegated, or AccountGroup admin
        return _isAuthorized(Operations.ADMIN, signer);
    }

    function _isValidSigner(address signer, bytes memory) internal view override returns (bool) {
        return hasPermission(Operations.CALL, signer);
    }

    function _updateState() internal virtual override {
        ERC6551AccountStorage.layout().state++;
    }

    /// @dev According to ERC6551, functions that modify state must alter the `uint256 state` variable
    function _beforeExecuteCall(address to, uint256 value, bytes calldata data)
        internal
        virtual
        override
        returns (address guard, bytes memory checkBeforeData)
    {
        _updateState();
        super._beforeExecuteCall(to, value, data);
    }

    /*===================
        AUTHORIZATION
    ===================*/

    function owner() public view override returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = ERC6551AccountLib.token();
        return _tokenOwner(chainId, tokenContract, tokenId);
    }

    function _tokenOwner(uint256 chainId, address tokenContract, uint256 tokenId)
        internal
        view
        virtual
        returns (address)
    {
        if (chainId != block.chainid) return address(0);
        if (tokenContract.code.length == 0) return address(0);

        try IERC721(tokenContract).ownerOf(tokenId) returns (address _owner) {
            return _owner;
        } catch {
            return address(0);
        }
    }

    /// @dev Sensitive account operations restricted to three tiered authorization hierarchy:
    ///   TBA owner || TBA permission || AccountGroup admin
    /// This provides owner autonomy, owner-delegated permissions, and multichain AccountGroup management
    function _isAuthorized(bytes8 _operation, address _sender) internal view returns (bool) {
        // check sender is TBA owner or has been granted relevant permission (or admin) on this account
        if (hasPermission(_operation, _sender)) return true;

        // allow AccountGroup admins to manage accounts on non-origin chains
        return _isAccountGroupAdmin(_sender);
    }

    /// @dev On non-origin chains, `owner()` returns the zero address, so multichain upgrades
    /// are enabled by permitting trusted AccountGroup admins
    function _isAccountGroupAdmin(address _sender) internal view returns (bool) {
        // fetch GroupAccount from contract bytecode
        bytes32 bytecodeSalt = ERC6551AccountLib.salt(address(this));
        address accountGroup = address(bytes20(bytecodeSalt));

        return IPermissions(accountGroup).hasPermission(Operations.ADMIN, _sender);
    }

    function _checkCanUpdateValidators() internal virtual override {
        _updateState();
        if (!_isAuthorized(Operations.VALIDATOR, msg.sender)) {
            revert IPermissions.PermissionDoesNotExist(Operations.VALIDATOR, msg.sender);
        }
    }

    function _checkCanUpdatePermissions() internal override {
        _updateState();
        if (!_isAuthorized(Operations.PERMISSIONS, msg.sender)) {
            revert IPermissions.PermissionDoesNotExist(Operations.PERMISSIONS, msg.sender);
        }
    }

    function _checkCanUpdateGuards() internal override {
        _updateState();
        if (!_isAuthorized(Operations.GUARDS, msg.sender)) {
            revert IPermissions.PermissionDoesNotExist(Operations.GUARDS, msg.sender);
        }
    }

    function _checkCanUpdateInterfaces() internal override {
        _updateState();
        if (!_isAuthorized(Operations.INTERFACE, msg.sender)) {
            revert IPermissions.PermissionDoesNotExist(Operations.INTERFACE, msg.sender);
        }
    }

    /// @dev Changes to extensions restricted to TBA owner or AccountGroupAdmin to prevent mutiny
    function _checkCanUpdateExtensions() internal override {
        _updateState();

        // revert if sender is neither owner nor AccountGroup admin, exclude permissions on this account
        (uint256 chainId,,) = ERC6551AccountLib.token();
        if (chainId == block.chainid) {
            require(msg.sender == owner(), "NOT_OWNER");
        } else if (!_isAccountGroupAdmin(msg.sender)) {
            revert IPermissions.PermissionDoesNotExist(Operations.ADMIN, msg.sender);
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override {
        // fetch GroupAccount from contract bytecode in the context of delegatecall
        bytes32 bytecodeSalt = ERC6551AccountLib.salt(address(this));
        address accountGroup = address(bytes20(bytecodeSalt));

        _updateState();
        IERC6551AccountGroup(accountGroup).checkValidAccountUpgrade(msg.sender, address(this), newImplementation);
    }
}
