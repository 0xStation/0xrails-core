// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IPermissions} from "./interface/IPermissions.sol";
import {PermissionsInternal} from "./PermissionsInternal.sol";
import {PermissionsStorage as Storage} from "./PermissionsStorage.sol";

abstract contract Permissions is PermissionsInternal {
    /*===========
        VIEWS
    ===========*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IPermissions).interfaceId;
    }

    /*=============
        SETTERS
    =============*/

    function addPermission(bytes8 operation, address account) public virtual {
        _checkCanUpdatePermissions();
        _addPermission(operation, account);
    }

    function removePermission(bytes8 operation, address account) public virtual {
        if (account != msg.sender) {
            _checkCanUpdatePermissions();
        }
        _removePermission(operation, account);
    }

    /*===================
        AUTHORIZATION
    ===================*/

    function _checkCanUpdatePermissions() internal virtual;
}
