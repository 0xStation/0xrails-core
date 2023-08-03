// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IPermissions {
    struct PermissionData {
        uint24 index; //     [0..23]
        uint40 updatedAt; // [24..63]
        bool exists; //      [64-71]
    }

    struct Permission {
        bytes8 operation;
        address account;
        uint40 updatedAt;
    }

    event PermissionGranted(bytes8 indexed operation, address indexed account);
    event PermissionRevoked(bytes8 indexed operation, address indexed account);

    error PermissionDoesNotExist(bytes8 operation, address account);
    error PermissionAlreadyExists(bytes8 operation, address account);

    // views
    function hasPermission(bytes8 operation, address account) external view returns (bool);
    function getAllPermissions() external view returns (Permission[] memory permissions);
    // setters
    function grantPermission(bytes8 operation, address account) external;
    function revokePermission(bytes8 operation, address account) external;
    function renouncePermission(bytes8 operation) external;
}
