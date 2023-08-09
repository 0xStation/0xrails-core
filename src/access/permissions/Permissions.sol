// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IPermissionsExternal, IPermissions} from "./interface/IPermissions.sol";
import {PermissionsInternal} from "./PermissionsInternal.sol";

abstract contract Permissions is PermissionsInternal, IPermissionsExternal {
    /*===========
        VIEWS
    ===========*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IPermissions).interfaceId;
    }

    /*=============
        SETTERS
    =============*/

    function grantPermission(bytes8 operation, address account) public virtual canUpdatePermissions {
        _grantPermission(operation, account);
    }

    function revokePermission(bytes8 operation, address account) public virtual canUpdatePermissions {
        _revokePermission(operation, account);
    }

    function renouncePermission(bytes8 operation) public virtual {
        _revokePermission(operation, msg.sender);
    }

    /*===================
        AUTHORIZATION
    ===================*/

    modifier canUpdatePermissions() {
        _checkCanUpdatePermissions();
        _;
    }

    function _checkCanUpdatePermissions() internal virtual;
}
