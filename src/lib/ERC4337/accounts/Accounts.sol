// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Mage} from "src/Mage.sol";
import {IAccount} from "src/lib/ERC4337/accounts/interface/IAccount.sol";
import {IEntryPoint} from "src/lib/ERC4337/accounts/interface/IEntryPoint.sol";
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
abstract contract Accounts is Mage, IAccount, IERC1271 {

    /*=============
        STORAGE
    ==============*/
    
    /// @dev This chain's EntryPoint contract address
    /// @notice Since this address is consistent across chains, `chainId` is included
    /// in the signature digest to prevent replay attacks
    address internal immutable _entryPoint;
    
    /// @dev In case of signature validation failure, return value need not include time range
    uint256 internal constant SIG_VALIDATION_FAILED = 1;

    /*=============
        ACCOUNTS
    ==============*/

    /// @param _entryPointAddress The contract address for this chain's ERC-4337 EntryPoint contract
    /// Official address for the most recent EntryPoint version is `0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789`
    constructor(address _entryPointAddress) {
        _entryPoint = _entryPointAddress;
    }

    /// @dev Function enabling EIP-4337 compliance as a smart contract wallet account
    /// @param userOp The UserOperation to validate before executing
    /// @param userOpHash Hash of the UserOperation data, used as signature digest
    /// @param missingAccountFunds Delta representing this account's missing funds in the EntryPoint contract
    /// Corresponds to minimum native currency that must be transferred to the EntryPoint to complete execution
    /// Can be 0 if this account has already deposited enough funds or if a paymaster is used
    // @return validationData //todo NatSpec: concatenated (authorizor, validUntil, validAfter)
    function validateUserOp(
        UserOperation calldata userOp, 
        bytes32 userOpHash, 
        uint256 missingAccountFunds
    ) public view returns (uint256 validationData) {
        // ensure msg.sender == entrypoint (|| self ?)
        // check signature- return false on mismatch. should be signed over chainId + entryPointAddress
        // check nonce maybe not entryPoint.getNonce(address(this), uint192 key)
        // check fee payment
        // return abi.encodePacked(authorizer, validUntil, validAfter) // authorizer == 0 for valid sig, 1 for invalid sig; not using signature aggregator
    }

    /// @dev Function to recover a signer address from the provided digest and signature
    /// and then verify whether the recovered signer address is a recognized Turnkey 
    /// @param hash The 32 byte digest derived by hashing signed message data
    /// @param signature The signature to be verified via recovery. Must be 65 bytes in length.
    /// @notice OZ's ECDSA library prevents the zero address from being returned as a result
    /// of `recover()`, even when `ecrecover()` does as part of assessing an invalid signature
    /// For this reason, checks preventing a call to `hasPermission[address(0x0)]` are not necessary
    function isValidSignature(bytes32 hash, bytes memory signature) public view returns (bytes4 magicValue) {
        // This contract inherit's Access.sol's `hasPermission()` so the owner and `ADMIN` permissions also return true
        if (hasPermission(Operations.EXECUTE_PERMIT, ECDSA.recover(hash, signature))) {
            magicValue = this.isValidSignature.selector;
        } else {
            // nonzero return value provides more explicit denial of invalid signatures than `0x00000000`
            return 0xffffffff;
        }
    }

    /*===========
        VIEWS
    ============*/

    /// @dev View function to get the ERC-4337 EntryPoint contract address for this chain
    function entryPoint() public view returns (address) {
        return entryPoint;
    }

    function getNonce() public view virtual returns (uint256) {
        return IEntryPoint(entryPoint).getNonce(address(this), 0);
    }

    /*===============
        OVERRIDES
    ===============*/

    /// @dev Declare explicit support for ERC1271 interface in addition to existing interfaces
    /// @param interfaceId The interfaceId to check for support
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return (interfaceId == type(IERC1271).interfaceId || super.supportsInterface(interfaceId));
    }

    function _checkCanUpdatePermissions() internal view override {
        _checkPermission(Operations.PERMISSIONS, msg.sender);
    }

    function _checkCanUpdateGuards() internal view override {
        _checkPermission(Operations.GUARDS, msg.sender);
    }

    function _checkCanExecute() internal view override {
        _checkPermission(Operations.EXECUTE, msg.sender);
    }

    /// @dev Provide control over ERC165 layout to addresses with INTERFACE permission
    function _checkCanUpdateInterfaces() internal view override {
        _checkPermission(Operations.INTERFACE, msg.sender);
    }
}