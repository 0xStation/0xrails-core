// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Mage} from "src/Mage.sol";
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
abstract contract Accounts is Mage, IERC1271 {

    // /*=============
    //     ACCOUNTS
    // ==============*/

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

    /// @notice This function must be overridden by contracts inheriting `Account` to delineate 
    /// the type of Account: `Bot`, `Member`, or `Group`
    // function owner() public view virtual override returns (address);

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