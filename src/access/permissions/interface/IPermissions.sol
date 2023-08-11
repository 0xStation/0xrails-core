// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PermissionsStorage} from "../PermissionsStorage.sol";

interface IPermissionsInternal {
    struct Permission {
        bytes8 operation;
        PermissionsStorage.OperationVariant variant;
        address account;
        uint40 updatedAt;
    }

    // events
    event PermissionUpdated(
        bytes8 indexed operation, address indexed account, PermissionsStorage.OperationVariant indexed variant
    );
    event PermissionRemoved(
        bytes8 indexed operation, address indexed account, PermissionsStorage.OperationVariant indexed variant
    );

    // errors
    error PermissionDoesNotExist(bytes8 operation, address account);
    error PermissionInvalid(bytes8 operation, PermissionsStorage.OperationVariant variant, address account);

    // views
    function hashOperation(string memory name) external view returns (bytes8);
    function hasPermission(bytes8 operation, address account) external view returns (bool);
    function getAllPermissions() external view returns (Permission[] memory permissions);
}

interface IPermissionsExternal {
    // setters
    function setPermission(bytes8 operation, PermissionsStorage.OperationVariant variant, address account) external;
    function removePermission(bytes8 operation, address account) external;
    function renouncePermission(bytes8 operation) external;
}

interface IPermissions is IPermissionsInternal, IPermissionsExternal {}
