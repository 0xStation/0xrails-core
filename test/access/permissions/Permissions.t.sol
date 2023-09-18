// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Permissions} from "src/access/permissions/Permissions.sol";
import {IPermissions} from "src/access/permissions/interface/IPermissions.sol";
import {PermissionsInternal} from "src/access/permissions/PermissionsInternal.sol";
import {PermissionsStorage} from "src/access/permissions/PermissionsStorage.sol";

contract PermissionsTest is Test, Permissions {
    bytes8 adminOp;

    // to store expected revert errors
    bytes err;

    function setUp() public {
        adminOp = hashOperation("ADMIN");
    }

    function test_packKey(bytes8 someOp, address someAddress) public {
        /* 
        .  Here is a deconstructed rundown including values at each step of function `_packKey(adminOp, address(type(uint160).max))`:
        .  ```return (uint256(uint64(operation)) | uint256(uint160(account)) << 64);```     
        .  Left-pack account by typecasting to uint256: 
        .  ```addressToUint == 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff```
        .  Shift left 64 bits, ie 8 bytes, which in hex is 16 digits: 
        .  ```leftShift64 == 0x00000000ffffffffffffffffffffffffffffffffffffffff0000000000000000```
        .  Left-pack operation by typecasting to uint256: 
        .  ```op == 0x000000000000000000000000000000000000000000000000df8b4c520ffe197c```
        .  Or packed operation against packed + shifted account: 
        .  ```_packedKey == 0x00000000ffffffffffffffffffffffffffffffffffffffffdf8b4c520ffe197c```
        */
        uint256 addressToUint = uint256(uint160(someAddress));
        uint256 leftShift64 = addressToUint << 64;
        uint256 op = uint256(uint64(adminOp));
        uint256 _packedKey = op | leftShift64;

        // desired / expected key:
        bytes32 expected = bytes32(abi.encodePacked(someAddress, adminOp)) >> 32;
        // expected == 0x00000000ffffffffffffffffffffffffffffffffffffffffdf8b4c520ffe197c
        assertEq(bytes32(_packedKey), expected);

        // using fuzzed operation
        uint256 key = PermissionsStorage._packKey(someOp, someAddress);
        uint256 expectedKey = uint256(bytes32(abi.encodePacked(someAddress, someOp)) >> 32);
        assertEq(key, expectedKey);
    }

    function test_unpackKey(bytes8 someOp, address someAddress) public {
        // insanity check
        uint256 key = PermissionsStorage._packKey(someOp, someAddress);
        (bytes8 unpackedOp, address unpackedAddr) = PermissionsStorage._unpackKey(key);
        assertEq(unpackedOp, someOp);
        assertEq(unpackedAddr, someAddress);
    }

    function test_addPermission(bytes8 operation, bytes8 operation2, address acc, address acc2) public {
        vm.assume(operation != operation2);

        // ensure permissions do not yet exist
        bool exists = hasPermission(operation, acc);
        bool exists2 = hasPermission(operation2, acc2);
        assertFalse(exists);
        assertFalse(exists2);
        assertEq(getAllPermissions().length, 0);

        // add Permission
        addPermission(operation, acc);
        Permission[] memory firstPermission = getAllPermissions();
        assertEq(firstPermission.length, 1);
        assertEq(firstPermission[0].operation, operation);
        assertEq(firstPermission[0].account, acc);
        assertEq(firstPermission[0].updatedAt, block.timestamp);
        assertTrue(hasPermission(operation, acc));
        _checkPermission(operation, acc); // reverts on failure

        // check storage
        PermissionsStorage.Layout storage layout = PermissionsStorage.layout();
        uint256 permissionKey = PermissionsStorage._packKey(operation, acc);
        PermissionsStorage.PermissionData memory permissionData = layout._permissions[permissionKey];
        assertTrue(permissionData.exists);
        assertEq(permissionData.updatedAt, block.timestamp);
        assertEq(permissionData.index, 0);

        // add Permission2
        addPermission(operation2, acc2);
        Permission[] memory twoPermissions = getAllPermissions();
        assertEq(twoPermissions.length, 2);
        assertEq(twoPermissions[1].operation, operation2);
        assertEq(twoPermissions[1].account, acc2);
        assertEq(twoPermissions[1].updatedAt, block.timestamp);
        assertTrue(hasPermission(operation2, acc2));
        _checkPermission(operation2, acc2); // reverts on failure

        // check storage
        uint256 permissionKey2 = PermissionsStorage._packKey(operation2, acc2);
        PermissionsStorage.PermissionData memory permissionData2 = layout._permissions[permissionKey2];
        assertTrue(permissionData2.exists);
        assertEq(permissionData2.updatedAt, block.timestamp);
        assertEq(permissionData2.index, 1);
    }

    function test_removePermission(address acc, uint8 numPermissions) public {
        vm.assume(numPermissions > 3);

        // add incrementing permissions starting from adminOp
        for (uint8 i; i < numPermissions; ++i) {
            bytes8 currentOp = bytes8(uint64(adminOp) + i);
            // add currentOp Permission to account
            addPermission(currentOp, acc);
        }

        // check added
        Permission[] memory permissions = getAllPermissions();
        assertEq(permissions.length, numPermissions);

        // remove a Permission
        removePermission(adminOp, acc);
        Permission[] memory newPermissions = getAllPermissions();
        uint256 newPermissionsLength = newPermissions.length;
        assertEq(newPermissionsLength, permissions.length - 1);
        // decrement newPermissionsLength to read last index of array
        assertEq(newPermissions[--newPermissionsLength].account, acc);
        assertEq(newPermissions[newPermissionsLength].updatedAt, 0);
        assertFalse(hasPermission(adminOp, acc));

        // check storage
        PermissionsStorage.Layout storage layout = PermissionsStorage.layout();
        uint256 permissionKey = PermissionsStorage._packKey(adminOp, acc);
        PermissionsStorage.PermissionData memory permissionData = layout._permissions[permissionKey];
        assertFalse(permissionData.exists);
        assertEq(permissionData.updatedAt, 0);
        assertEq(permissionData.index, 0);

        // _checkPermission should now revert on deleted permission
        err = abi.encodeWithSelector(PermissionDoesNotExist.selector, adminOp, acc);
        vm.expectRevert(err);
        _checkPermission(adminOp, acc);

        // remove another Permission
        removePermission(bytes8(uint64(adminOp) + uint64(newPermissionsLength)), acc);
        assertEq(getAllPermissions().length, newPermissionsLength);

        // remove the rest
        for (uint8 j = uint8(newPermissionsLength); j > 0;) {
            // decrementing first ensures iter is not the first op removed; j > 0 prevents re-revoking adminOp
            --j;

            removePermission(bytes8(uint64(adminOp) + j), acc);
        }
        // assert all permissions were removed
        assertEq(getAllPermissions().length, 0);
    }

    function test_removePermissionRevertPermissionDoesNotExist(
        bytes8 operation,
        bytes8 operation2,
        address acc,
        address acc2
    ) public {
        vm.assume(acc != acc2); // either operations or accounts may collide but not both

        // add permissions
        addPermission(operation, acc);
        addPermission(operation2, acc2);

        // remove them, twice
        removePermission(operation, acc);
        err = abi.encodeWithSelector(PermissionDoesNotExist.selector, operation, acc);
        vm.expectRevert(err);
        removePermission(operation, acc);

        removePermission(operation2, acc2);
        err = abi.encodeWithSelector(PermissionDoesNotExist.selector, operation2, acc2);
        vm.expectRevert(err);
        removePermission(operation2, acc2);
    }

    function test_renouncePermission(address acc, uint8 numPermissions) public {
        vm.assume(numPermissions > 0);
        vm.assume(acc != address(0x0));

        // add permissions for acc
        for (uint256 i; i < numPermissions; ++i) {
            addPermission(bytes8(uint64(adminOp) + uint64(i)), acc);
        }

        assertEq(getAllPermissions().length, numPermissions);

        // acc doesn't want them, renounces adminOp then the rest
        vm.prank(acc);
        this.removePermission(adminOp, acc);
        assertEq(getAllPermissions().length, numPermissions--);
        err = abi.encodeWithSelector(PermissionDoesNotExist.selector, adminOp, acc);
        vm.expectRevert(err);
        removePermission(adminOp, acc);
        assertFalse(hasPermission(adminOp, acc));

        PermissionsStorage.Layout storage layout = PermissionsStorage.layout();
        vm.startPrank(acc);
        // renounce permissions starting from adminOp + 1
        for (uint64 j; j < numPermissions;) {
            ++j;
            bytes8 currentOp = bytes8(uint64(adminOp) + j);

            this.removePermission(currentOp, address(this));
            vm.expectRevert(err);
            removePermission(adminOp, acc);

            Permission[] memory currentPermissions = getAllPermissions();
            assertEq(currentPermissions.length, numPermissions - j);
            assertEq(currentPermissions[j].operation, currentOp);
            assertEq(currentPermissions[j].account, acc);
            assertEq(currentPermissions[j].updatedAt, block.timestamp);
            assertFalse(hasPermission(currentOp, acc));

            err = abi.encodeWithSelector(PermissionDoesNotExist.selector, currentOp, acc);
            vm.expectRevert(err);
            _checkPermission(currentOp, acc);

            // check storage
            uint256 permissionKey = PermissionsStorage._packKey(currentOp, acc);
            PermissionsStorage.PermissionData memory permissionData = layout._permissions[permissionKey];
            assertFalse(permissionData.exists);
            assertEq(permissionData.updatedAt, 0);
            assertEq(permissionData.index, 0);
        }

        assertEq(getAllPermissions().length, 0);
    }

    /*==============
        OVERRIDES
    ==============*/

    function _checkCanUpdatePermissions() internal override {}
}
