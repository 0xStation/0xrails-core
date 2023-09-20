// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IPermissions} from "./interface/IPermissions.sol";
import {PermissionsInternal} from "./PermissionsInternal.sol";
import {PermissionsStorage as Storage} from "./PermissionsStorage.sol";

abstract contract Permissions is PermissionsInternal {
    /*===========
        VIEWS
    ===========*/

    /// @dev Function to implement ERC-165 compliance 
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IPermissions).interfaceId;
    }

    /*=============
        SETTERS
    =============*/

    /// @dev Function to add permission for an address to carry out an operation
    /// @param operation The operation to permit
    /// @param account The account address to be granted permission for the operation
    function addPermission(bytes8 operation, address account) public virtual {
        _checkCanUpdatePermissions();
        _addPermission(operation, account);
    }

    /// @dev Function to remove permission for an address to carry out an operation
    /// @param operation The operation to restrict
    /// @param account The account address whose permission to remove
    function removePermission(bytes8 operation, address account) public virtual {
        if (account != msg.sender) {
            _checkCanUpdatePermissions();
        }
        _removePermission(operation, account);
    }

    /*===================
        AUTHORIZATION
    ===================*/

    /// @dev Function to implement access control restricting setter functions
    function _checkCanUpdatePermissions() internal virtual;
}
