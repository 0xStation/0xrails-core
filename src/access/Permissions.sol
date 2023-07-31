// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IPermissions} from "./interface/IPermissions.sol";

abstract contract Permissions is IPermissions {
    uint256[] internal _permissionKeys;
    mapping(uint256 => PermissionData) internal _permissions;

    /*===========
        VIEWS
    ===========*/

    modifier onlyPermission(bytes8 operation) {
        _checkPermission(operation, msg.sender);
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IPermissions).interfaceId;
    }

    function hashOperation(string memory name) public pure returns (bytes8) {
        return bytes8(keccak256(abi.encodePacked(name)));
    }

    function hasPermission(bytes8 operation, address account) public view virtual returns (bool) {
        return _permissions[_packKey(operation, account)].exists;
    }

    function getAllPermissions() public view returns (Permission[] memory permissions) {
        uint256 len = _permissionKeys.length;
        permissions = new Permission[](len);
        for (uint256 i; i < len; i++) {
            uint256 permissionKey = _permissionKeys[i];
            (bytes8 operation, address account) = _unpackKey(permissionKey);
            permissions[i] = Permission(operation, account);
        }
        return permissions;
    }

    /*=============
        SETTERS
    =============*/

    modifier canUpdatePermissions() {
        _checkCanUpdatePermissions();
        _;
    }

    function grantPermission(bytes8 operation, address account) public virtual canUpdatePermissions {
        _grantPermission(operation, account, 0);
    }

    function revokePermission(bytes8 operation, address account) public virtual canUpdatePermissions {
        _revokePermission(operation, account);
    }

    function renouncePermission(bytes8 operation) public virtual {
        _revokePermission(operation, msg.sender);
    }

    /*===============
        INTERNALS
    ===============*/

    function _packKey(bytes8 operation, address account) internal pure returns (uint256) {
        return (uint256(bytes32(operation)) | uint256(uint160(account)) << 64);
    }

    function _unpackKey(uint256 key) internal pure returns (bytes8 operation, address account) {
        operation = bytes8(uint64(key));
        account = address(uint160(key >> 64));
        return (operation, account);
    }

    function _checkPermission(bytes8 operation, address account) internal view {
        if (!hasPermission(operation, account)) revert PermissionDoesNotExist(operation, account);
    }

    function _grantPermission(bytes8 operation, address account, uint232 info) internal {
        uint256 permissionKey = _packKey(operation, account);
        PermissionData memory oldPermission = _permissions[permissionKey];
        if (oldPermission.exists) revert PermissionAlreadyExists(operation, account);

        PermissionData memory permission = PermissionData(uint16(_permissionKeys.length), true, info); // new length will be `len + 1`, so this permission has index `len`

        _permissions[permissionKey] = permission;
        _permissionKeys.push(permissionKey); // set new permissionKey at index and increment length

        emit PermissionGranted(operation, account);
    }

    function _revokePermission(bytes8 operation, address account) internal {
        uint256 permissionKey = _packKey(operation, account);
        PermissionData memory oldPermissionData = _permissions[permissionKey];
        if (!oldPermissionData.exists) revert PermissionDoesNotExist(operation, account);

        uint256 lastIndex = _permissionKeys.length - 1;
        // if removing item not at the end of the array, swap item with last in array
        if (oldPermissionData.index < lastIndex) {
            uint256 lastPermissionKey = _permissionKeys[lastIndex];
            PermissionData memory lastPermissionData = _permissions[lastPermissionKey];
            lastPermissionData.index = oldPermissionData.index;
            _permissionKeys[oldPermissionData.index] = lastPermissionKey;
            _permissions[lastPermissionKey] = lastPermissionData;
        }
        delete _permissions[permissionKey];
        _permissionKeys.pop(); // delete guard in last index and decrement length

        emit PermissionRevoked(operation, account);
    }

    function _updatePermission(bytes8 operation, address account, uint232 info) internal {
        uint256 permissionKey = _packKey(operation, account);
        PermissionData storage permission = _permissions[permissionKey];
        if (!permission.exists) revert PermissionDoesNotExist(operation, account);

        permission.info = info;
    }

    /*===================
        AUTHORIZATION
    ===================*/

    function _checkCanUpdatePermissions() internal virtual {}
}
