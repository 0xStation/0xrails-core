// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Mage} from "src/Mage.sol";
import {IAccount} from "src/lib/ERC4337/interface/IAccount.sol";
import {IEntryPoint} from "src/lib/ERC4337/interface/IEntryPoint.sol";
import {UserOperation} from "src/lib/ERC4337/utils/UserOperation.sol";
import {ModularValidationInternal} from "src/lib/ERC4337/validator/ModularValidationInternal.sol";
import {IValidator} from "src/lib/ERC4337/validator/interface/IValidator.sol";
import {Operations} from "src/lib/Operations.sol";
import {IOwnable} from "src/access/ownable/interface/IOwnable.sol";
import {OwnableInternal} from "src/access/ownable/OwnableInternal.sol";
import {Access} from "src/access/Access.sol";
import {SupportsInterface} from "src/lib/ERC165/SupportsInterface.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {IERC1271} from "openzeppelin-contracts/interfaces/IERC1271.sol";

/// @title Station Network Account Abstract Contract
/// @author 👦🏻👦🏻.eth

/// @dev This abstract contract provides scaffolding for Station's Account signature validation
/// ERC1271 and ERC4337 compliance in combination with Mage's Permissions system
/// to provide convenient and modular private key management on an infrastructural level
abstract contract Account is Mage, IAccount, IERC1271, ModularValidationInternal {

    /*=============
        ACCOUNTS
    ==============*/
    
    /// @dev This chain's EntryPoint contract address
    address public immutable entryPoint;

    /// @param _entryPointAddress The contract address for this chain's ERC-4337 EntryPoint contract
    /// Official address for the most recent EntryPoint version is `0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789`
    constructor(address _entryPointAddress) {
        entryPoint = _entryPointAddress;
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

        // extract validator address using cheap calldata slicing before decoding 
        address validator = address(bytes20(userOp.signature[12:32]));

        if (isValidator(validator)) {
            ( , address signer, bytes memory nestedSig) = abi.decode(userOp.signature, (address, address, bytes));
            // copy userOp into memory and format for Validator module
            UserOperation memory formattedUserOp = userOp;
            formattedUserOp.signature = abi.encode(signer, nestedSig);

            uint256 ret = IValidator(validator).validateUserOp(formattedUserOp, userOpHash, missingAccountFunds);
            // if validator rejects sig, terminate with status code 1
            if (ret != 0) return ret;
        } else {
            // if validator address not recognized, terminate with status code 1
            return 1;
        }

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

    /// @dev Function to recover a signer address from the provided hash and signature
    /// and then verify whether the recovered signer address is a recognized Turnkey 
    /// @param hash The 32 byte digest derived by hashing signed message data. Sadly, name is canonical in ERC1271.
    /// @param signature The signature to be verified via recovery. Must be prepended with validator address
    function isValidSignature(bytes32 hash, bytes memory signature) public view returns (bytes4 magicValue) {
        // note: This impl assumes the nested sig within `UserOperation.signature` is created using EIP-712

        // extract validator address and sig formatted for validator
        (address validator, address signer, bytes memory nestedSig) = abi.decode(signature, (address, address, bytes));

        if (isValidator(validator)) {
            // format call for Validator module
            bytes4 ret = IValidator(validator).isValidSignature(hash, abi.encode(signer, nestedSig));
            // validator will return either correct `magicValue` or error code `INVALID_SIGNER`
            magicValue = ret;
        } else {
            // terminate with empty `magicValue`, indicating unrecognized validator
            return bytes4(0);
        }
    }

    /*===============
        INTERNALS
    ===============*/

    /// @dev View function to limit callers to only the EntryPoint contract of this chain
    function _checkSenderIsEntryPoint() internal view {
        if (msg.sender != entryPoint) revert NotEntryPoint(msg.sender);
    }

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

    /// @dev Permission to `Call::call()` via signature validation is restricted to either
    /// the EntryPoint, the owner, or entities possessing the `CALL`or `ADMIN` permissions
    /// @notice Mutiny by Turnkeys is prevented by granting them only the `CALL_PERMIT` permission
    function _checkCanCall() internal view override {
        bool auth = (msg.sender == entryPoint || hasPermission(Operations.CALL, msg.sender));
        if (!auth) revert PermissionDoesNotExist(Operations.CALL, msg.sender);
    }

    /// @dev Provides control over ERC165 layout to addresses with `INTERFACE` permission
    function _checkCanUpdateInterfaces() internal view override {
        _checkPermission(Operations.INTERFACE, msg.sender);
    }

    /// @notice Functions to be overridden by child contracts inheriting from this one
    function preFundEntryPoint() external payable virtual;

    function withdrawFromEntryPoint(address payable recipient, uint256 amount) external virtual;
    
    /// @dev Override with careful consideration of access control
    function addValidator(address validator) public virtual override;

    /// @dev Override with careful consideration of access control
    function removeValidator(address validator) public virtual override;
}