// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PermissionsStorage} from "../PermissionsStorage.sol";

interface IPermissionsInternal {
    struct Permission {
        bytes8 operation;
        address account;
        uint40 updatedAt;
    }

    // events
    event PermissionAdded(bytes8 indexed operation, address indexed account);
    event PermissionRemoved(bytes8 indexed operation, address indexed account);

    // errors
    error PermissionAlreadyExists(bytes8 operation, address account);
    error PermissionDoesNotExist(bytes8 operation, address account);
}

/// @notice Since the Solidity compiler ignores inherited functions, function declarations are made
/// at the top level so their selectors are properly XORed into a nonzero `interfaceId`
interface IPermissions is IPermissionsInternal {
    // IPermissionsInternal views
    function hashOperation(string memory name) external view returns (bytes8);
    function hasPermission(bytes8 operation, address account) external view returns (bool);
    function getAllPermissions() external view returns (Permission[] memory permissions);
    // external setters
    function addPermission(bytes8 operation, address account) external;
    function removePermission(bytes8 operation, address account) external;
}
