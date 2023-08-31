// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Mage} from "src/Mage.sol";
import {IAccount} from "src/lib/ERC4337/interface/IAccount.sol";
import {IEntryPoint} from "src/lib/ERC4337/interface/IEntryPoint.sol";
import {ERC4337Internal} from "src/lib/ERC4337/utils/ERC4337Internal.sol";
import {ERC4337Storage} from "src/lib/ERC4337/utils/ERC4337Storage.sol";
import {UserOperation} from "src/lib/ERC4337/utils/UserOperation.sol";
import {ModularValidationInternal} from "src/lib/ERC4337/validator/ModularValidationInternal.sol";
import {ModularValidationStorage} from "src/lib/ERC4337/validator/ModularValidationStorage.sol";
import {IValidator} from "src/lib/ERC4337/validator/interface/IValidator.sol";
import {Operations} from "src/lib/Operations.sol";
import {IOwnable} from "src/access/ownable/interface/IOwnable.sol";
import {OwnableInternal} from "src/access/ownable/OwnableInternal.sol";
import {Access} from "src/access/Access.sol";
import {SupportsInterface} from "src/lib/ERC165/SupportsInterface.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {IERC1271} from "openzeppelin-contracts/interfaces/IERC1271.sol";

/// @title Station Network Accounts Manager Abstract Contract
/// @author 👦🏻👦🏻.eth

/// @dev This abstract contract provides scaffolding Station's Accounts signature validation
/// ERC1271-compliance in combination with Mage's Permissions::EXECUTE_PERMIT system
/// provides convenient and modular private key management on an infrastructural level
abstract contract Accounts is Mage, IAccount, IERC1271, ERC4337Internal, ModularValidationInternal {

    /*=============
        ACCOUNTS
    ==============*/

    /// @param _entryPointAddress The contract address for this chain's ERC-4337 EntryPoint contract
    /// Official address for the most recent EntryPoint version is `0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789`
    constructor(address _entryPointAddress) {
        ERC4337Storage.layout().entryPoint = _entryPointAddress;
        // error codes
        ERC4337Storage.layout().SIG_VALIDATION_FAILED = 1;
        ERC4337Storage.layout().INVALID_SIGNER = hex'ffffffff';
    }

    /// @dev Function enabling EIP-4337 compliance as a smart contract wallet account
    /// @param userOp The UserOperation to validate before executing
    /// @param userOpHash Hash of the UserOperation data, used as signature digest
    /// @param missingAccountFunds Delta representing this account's missing funds in the EntryPoint contract
    /// Corresponds to minimum native currency that must be transferred to the EntryPoint to complete execution
    /// Can be 0 if this account has already deposited enough funds or if a paymaster is used
    /** 
    *   @return validationData A packed uint256 of three concatenated variables
    *   ie: `uint256(abi.encodePacked(address authorizor, uint48 validUntil, uint48 validAfter))`
    *   where `authorizer` can be one of the following:
    *       1. A signature aggregator contract, inheriting IAggregator.sol, to use for validation
    *       2. An exit status code `bytes20(0x01)` representing signature validation failure 
    *       3. An empty `bytes20(0x0)` representing successful signature validation
    */
    function validateUserOp(
        UserOperation calldata userOp, 
        bytes32 userOpHash, 
        uint256 missingAccountFunds
    ) public virtual returns (uint256 validationData) {
        // only EntryPoint should call this function to prevent frontrunning of valid signatures
        _checkSenderIsEntryPoint();

        // extract validator address
        address validator = address(bytes20(userOp.signature[:20]));
        if (isValidator(validator)) {
            // copy userOp into memory and format for Validator module
            UserOperation memory formattedUserOp = userOp;
            formattedUserOp.signature = userOp.signature[20:];

            uint256 ret = IValidator(validator).validateUserOp(formattedUserOp, userOpHash, missingAccountFunds);
            // if validator rejects sig, terminate with status code 1
            if (ret != 0) return uint256(ERC4337Storage.layout().SIG_VALIDATION_FAILED);
        } else {
            // terminate with status code 1
            return uint256(ERC4337Storage.layout().SIG_VALIDATION_FAILED);
        }

        //TODO ADD SUPPORTSINTERFACE(EXECUTE) TODO make entrypoint permission permanent TODO add IAccounts parent

        /// @notice BLS sig aggregator and timestamp expiry are not currently supported by this contract 
        /// so `bytes20(0x0)` and `bytes6(0x0)` suffice. To enable support for aggregator and timestamp expiry,
        /// override the following params
        bytes20 authorizer;
        bytes6 validUntil;
        bytes6 validAfter;

        validationData = uint256(bytes32(abi.encodePacked(authorizer, validUntil, validAfter)));

        /// @notice nonce collision is managed entirely by the EntryPoint, but validation hook optionality
        /// for child contracts is provided here as `_checkNonce()` may be overridden
        _checkNonce();

        // check fee payment
        if (missingAccountFunds != 0) {
            _preFund(missingAccountFunds);
        }
    }

    /// @dev Function to recover a signer address from the provided digest and signature
    /// and then verify whether the recovered signer address is a recognized Turnkey 
    /// @param hash The 32 byte digest derived by hashing signed message data. Sadly, name is canonical in ERC1271.
    /// @param signature The signature to be verified via recovery. Must be prepended with validator address
    function isValidSignature(bytes32 hash, bytes memory signature) public view returns (bytes4 magicValue) {
        // note: This impl assumes the nested sig within `UserOperation.signature` is created using EIP-712

        // extract validator address and sig formatted for validator
        (address validator, bytes memory formattedSig) = abi.decode(signature, (address, bytes));
        if (isValidator(validator)) {
            // format call for Validator module
            bytes4 ret = IValidator(validator).isValidSignature(hash, formattedSig);

            // if validator returns wrong `magicValue`, return error code
            if (ret != this.isValidSignature.selector) return ERC4337Storage.layout().INVALID_SIGNER;
            
            magicValue = ret;
        } else {
            // terminate with empty `magicValue`, indicating unrecognized validator
            return bytes4(0);
        }
    }

    /*===============
        INTERNALS
    ===============*/

    /// @dev Since nonce management and collision checks are handled entirely by the EntryPoint,
    /// this function is left empty for contracts inheriting from this one to use EntryPoint's defaults
    /// If sequential `UserOperation` nonce ordering is desired, override this, eg: `require(nonce < type(uint64).max)`
    function _checkNonce() internal view virtual {}

    /// @dev Function to pre-fund the EntryPoint contract with delta of native currency funds required for a UserOperation
    /// By default, this function only sends enough funds to complete the current context's UserOperation
    /// Override if sending custom amounts > `_missingAccountFunds` (or < if reverts are preferrable)
    function _preFund(uint256 _missingAccountFunds) internal virtual {
        (bool r, ) = payable(msg.sender).call{ value: _missingAccountFunds }('');
        require(r);
    }

    /*===============
        OVERRIDES
    ===============*/

    /// @dev Function to add the address of a Validator module to storage
    function addValidator(address validator) public override {
        ModularValidationStorage.Layout storage layout = ModularValidationStorage.layout();
        layout._validators[validator] = true;
    }

    /// @dev Function to remove the address of a Validator module to storage
    function removeValidator(address validator) public override {
        ModularValidationStorage.Layout storage layout = ModularValidationStorage.layout();
        layout._validators[validator] = false;
    }

    /// @dev Declare explicit support for ERC1271 interface in addition to existing interfaces
    /// @param interfaceId The interfaceId to check for support
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return (
            interfaceId == type(IERC1271).interfaceId
                || interfaceId == type(IAccount).interfaceId
                || super.supportsInterface(interfaceId)
        );
    }

    /// @dev Provides control over Turnkey addresses to the owner only
    /// @notice Permission to `addPermission(Operations.CALL_PERMIT)`, which is the intended
    /// function call to be called by the owner for adding valid signer accounts such as Turnkeys,
    /// is restricted to only the owner
    function _checkCanUpdatePermissions() internal view override {
        _checkPermission(Operations.PERMISSIONS, msg.sender);
    }

    function _checkCanUpdateGuards() internal view override {
        _checkPermission(Operations.GUARDS, msg.sender);
    }

    /// @dev Provides control over `EXECUTE` permission to the owner only
    /// @notice Permission to `execute()` via signature validation is restricted to either the Entrypoint,
    /// the owner, or entities possessing the `EXECUTE_PERMIT`or `ADMIN` permissions
    function _checkCanExecute() internal view override {
        bool auth = (msg.sender == entryPoint() || hasPermission(Operations.CALL, msg.sender));
        if (!auth) revert PermissionDoesNotExist(Operations.CALL, msg.sender);
    }

    /// @dev Provides control over ERC165 layout to addresses with `INTERFACE` permission
    function _checkCanUpdateInterfaces() internal view override {
        _checkPermission(Operations.INTERFACE, msg.sender);
    }

    /// @notice Functions to be overridden by child contracts inheriting from this one
    /// These ensure that funds do not get locked by deployed contracts inheriting from `Mage`
    /// which possesses a payable `receive()` fallback
    function preFundEntryPoint() external payable virtual;
    function withdrawFromEntryPoint(address payable recipient, uint256 amount) external virtual;
}