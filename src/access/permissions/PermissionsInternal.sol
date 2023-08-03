// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IPermissionsInternal} from "./interface/IPermissions.sol";
import {PermissionsStorage} from "./PermissionsStorage.sol";

abstract contract PermissionsInternal is IPermissionsInternal {
    /*===========
        VIEWS
    ===========*/

    function hashOperation(string memory name) public pure returns (bytes8) {
        return PermissionsStorage._hashOperation(name);
    }

    function hasPermission(bytes8 operation, address account) public view virtual returns (bool) {
        return PermissionsStorage.layout()._permissions[PermissionsStorage._packKey(operation, account)].exists;
    }

    function getAllPermissions() public view returns (Permission[] memory permissions) {
        PermissionsStorage.Layout storage layout = PermissionsStorage.layout();
        uint256 len = layout._permissionKeys.length;
        permissions = new Permission[](len);
        for (uint256 i; i < len; i++) {
            uint256 permissionKey = layout._permissionKeys[i];
            (bytes8 operation, address account) = PermissionsStorage._unpackKey(permissionKey);
            permissions[i] = Permission(operation, account, layout._permissions[permissionKey].updatedAt);
        }
        return permissions;
    }

    /*=============
        SETTERS
    =============*/

    function _grantPermission(bytes8 operation, address account) internal {
        PermissionsStorage.Layout storage layout = PermissionsStorage.layout();
        uint256 permissionKey = PermissionsStorage._packKey(operation, account);
        if (layout._permissions[PermissionsStorage._packKey(operation, account)].exists) {
            revert PermissionAlreadyExists(operation, account);
        }

        PermissionsStorage.PermissionData memory permission =
            PermissionsStorage.PermissionData(uint24(layout._permissionKeys.length), uint40(block.timestamp), true); // new length will be `len + 1`, so this permission has index `len`

        layout._permissions[permissionKey] = permission;
        layout._permissionKeys.push(permissionKey); // set new permissionKey at index and increment length

        emit PermissionGranted(operation, account);
    }

    function _revokePermission(bytes8 operation, address account) internal {
        PermissionsStorage.Layout storage layout = PermissionsStorage.layout();
        uint256 permissionKey = PermissionsStorage._packKey(operation, account);
        PermissionsStorage.PermissionData memory oldPermissionData = layout._permissions[permissionKey];
        if (!oldPermissionData.exists) revert PermissionDoesNotExist(operation, account);

        uint256 lastIndex = layout._permissionKeys.length - 1;
        // if removing item not at the end of the array, swap item with last in array
        if (oldPermissionData.index < lastIndex) {
            uint256 lastPermissionKey = layout._permissionKeys[lastIndex];
            PermissionsStorage.PermissionData memory lastPermissionData = layout._permissions[lastPermissionKey];
            lastPermissionData.index = oldPermissionData.index;
            layout._permissionKeys[oldPermissionData.index] = lastPermissionKey;
            layout._permissions[lastPermissionKey] = lastPermissionData;
        }
        delete layout._permissions[permissionKey];
        layout._permissionKeys.pop(); // delete guard in last index and decrement length

        emit PermissionRevoked(operation, account);
    }

    /*===================
        AUTHORIZATION
    ===================*/

    modifier onlyPermission(bytes8 operation) {
        _checkPermission(operation, msg.sender);
        _;
    }

    function _checkPermission(bytes8 operation, address account) internal view {
        if (!hasPermission(operation, account)) revert PermissionDoesNotExist(operation, account);
    }
}
