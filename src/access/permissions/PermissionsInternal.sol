// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IPermissionsInternal} from "./interface/IPermissions.sol";
import {PermissionsStorage as Storage} from "./PermissionsStorage.sol";

abstract contract PermissionsInternal is IPermissionsInternal {
    /*===========
        VIEWS
    ===========*/

    function hashOperation(string memory name) public pure returns (bytes8) {
        return Storage._hashOperation(name);
    }

    function hasPermission(bytes8 operation, Storage.OperationVariant variant, address account)
        public
        view
        virtual
        returns (bool)
    {
        Storage.PermissionData memory permission = Storage.layout()._permissions[Storage._packKey(operation, account)];

        bool operationMatch;
        if (permission.variant == Storage.OperationVariant.PERMIT_AND_EXECUTE || permission.variant == variant) operationMatch = true;
        return permission.exists && operationMatch;
    }

    function getAllPermissions() public view returns (Permission[] memory permissions) {
        Storage.Layout storage layout = Storage.layout();
        uint256 len = layout._permissionKeys.length;
        permissions = new Permission[](len);
        for (uint256 i; i < len; i++) {
            uint256 permissionKey = layout._permissionKeys[i];
            (bytes8 operation, address account) = Storage._unpackKey(permissionKey);
            Storage.PermissionData memory permission = layout._permissions[permissionKey];
            permissions[i] = Permission(operation, permission.variant, account, permission.updatedAt);
        }
        return permissions;
    }

    /*=============
        SETTERS
    =============*/

    function _setPermission(bytes8 operation, Storage.OperationVariant variant, address account) internal {
        Storage.Layout storage layout = Storage.layout();
        uint256 permissionKey = Storage._packKey(operation, account);
        if (layout._permissions[permissionKey].exists) {
            // update permission

            layout._permissions[permissionKey].updatedAt = uint40(block.timestamp);
            layout._permissions[permissionKey].variant = variant;
        } else {
            // add new permission

            // new length will be `len + 1`, so this permission has index `len`
            Storage.PermissionData memory permission =
                Storage.PermissionData(uint24(layout._permissionKeys.length), uint40(block.timestamp), true, variant);

            layout._permissions[permissionKey] = permission;
            layout._permissionKeys.push(permissionKey); // set new permissionKey at index and increment length
        }

        emit PermissionUpdated(operation, account, variant);
    }

    function _removePermission(bytes8 operation, address account) internal {
        Storage.Layout storage layout = Storage.layout();
        uint256 permissionKey = Storage._packKey(operation, account);
        Storage.PermissionData memory oldPermissionData = layout._permissions[permissionKey];
        if (!oldPermissionData.exists) {
            revert PermissionDoesNotExist(operation, account);
        }

        uint256 lastIndex = layout._permissionKeys.length - 1;
        // if removing item not at the end of the array, swap item with last in array
        if (oldPermissionData.index < lastIndex) {
            uint256 lastPermissionKey = layout._permissionKeys[lastIndex];
            Storage.PermissionData memory lastPermissionData = layout._permissions[lastPermissionKey];
            lastPermissionData.index = oldPermissionData.index;
            layout._permissionKeys[oldPermissionData.index] = lastPermissionKey;
            layout._permissions[lastPermissionKey] = lastPermissionData;
        }
        delete layout._permissions[permissionKey];
        layout._permissionKeys.pop(); // delete guard in last index and decrement length

        emit PermissionRemoved(operation, account, oldPermissionData.variant);
    }

    /*===================
        AUTHORIZATION
    ===================*/

    modifier onlyPermission(bytes8 operation, Storage.OperationVariant variant) {
        _checkPermission(operation, variant, msg.sender);
        _;
    }

    function _checkPermission(bytes8 operation, Storage.OperationVariant variant, address account) internal view {
        if (!hasPermission(operation, variant, account)) revert PermissionInvalid(operation, variant, account);
    }
}
