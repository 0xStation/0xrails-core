// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IPermissionsExternal, IPermissions} from "./interface/IPermissions.sol";
import {PermissionsInternal} from "./PermissionsInternal.sol";
import {PermissionsStorage as Storage} from "./PermissionsStorage.sol";

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

    function setPermission(bytes8 operation, Storage.OperationVariant variant, address account)
        public
        virtual
        canUpdatePermissions
    {
        _setPermission(operation, variant, account);
    }

    function removePermission(bytes8 operation, address account) public virtual canUpdatePermissions {
        _removePermission(operation, account);
    }

    function renouncePermission(bytes8 operation) public virtual {
        _removePermission(operation, msg.sender);
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
