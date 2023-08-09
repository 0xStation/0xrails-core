// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Permissions} from "src/access/permissions/Permissions.sol";
import {IPermissionsExternal, IPermissions} from "src/access/permissions/interface/IPermissions.sol";
import {PermissionsInternal} from "src/access/permissions/PermissionsInternal.sol";
import {PermissionsStorage} from "src/access/permissions/PermissionsStorage.sol";

contract PermissionsTest is Test, Permissions {

    bytes8 adminOp;

    // to store expected revert errors
    bytes err;

    // errors from IPermissions.sol
    // error PermissionDoesNotExist(bytes8 operation, address account);
    // error PermissionAlreadyExists(bytes8 operation, address account);
    
    function setUp() public {
        adminOp = hashOperation('ADMIN');
    }

    function test_packKey(bytes8 someOp, address someAddress) public {
        // here is deconstructed `_packKey()` with step by step values
        // _packKey(): return (uint256(uint64(operation)) | uint256(uint160(account)) << 64);
        uint256 addressToUint = uint256(uint160(someAddress)); 
        // addressToUint == 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff
        uint256 leftShift64 = addressToUint << 64; // shifted left 64 bits == 8 bytes
        // leftShift64 == 0x00000000ffffffffffffffffffffffffffffffffffffffff0000000000000000
        uint256 op = uint256(uint64(adminOp));
        // op == 0x000000000000000000000000000000000000000000000000df8b4c520ffe197c
        uint256 _packedKey = op | leftShift64; // combine uinted operation with leftshifted address
        // _packedKey == 0xffffffffffffffffffffffffffffffffffffffffdf8b4c520ffe197c

        // desired / expected key:
        bytes32 expected = bytes32(abi.encodePacked(someAddress, adminOp)) >> 32;
        // expected == 0xffffffffffffffffffffffffffffffffffffffffdf8b4c520ffe197c
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

    function test_grantPermission(bytes8 operation, bytes8 operation2, address acc, address acc2) public {
        vm.assume(operation != operation2);

        // ensure permissions do not yet exist
        bool exists = hasPermission(operation, acc);
        bool exists2 = hasPermission(operation2, acc2);
        assertFalse(exists); 
        assertFalse(exists2);
        assertEq(getAllPermissions().length, 0);

        // add Permission
        grantPermission(operation, acc);
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
        grantPermission(operation2, acc2);
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

    function test_grantPermissionRevertPermissionAlreadyExists(
        bytes8 operation, 
        bytes8 operation2, 
        address acc, 
        address acc2
    ) public {
        vm.assume(acc != acc2); // either operations or accounts may collide but not both

        grantPermission(operation, acc);
        grantPermission(operation2, acc2);

        err = abi.encodeWithSelector(PermissionAlreadyExists.selector, operation, acc);
        vm.expectRevert(err);
        grantPermission(operation, acc);
        err = abi.encodeWithSelector(PermissionAlreadyExists.selector, operation2, acc2);
        vm.expectRevert(err);
        grantPermission(operation2, acc2);
    }

    function test_revokePermission(address acc, uint8 numPermissions) public {
        vm.assume(numPermissions > 3);
        
        // add permissions
        for (uint8 i; i < numPermissions; ++i) {
            // add adminOp Permission to account 
            grantPermission(bytes8(uint64(adminOp) + i), acc);
        }

        Permission[] memory permissions = getAllPermissions();
        assertEq(permissions.length, numPermissions);

        // remove a Permission
        revokePermission(bytes8(uint64(adminOp) + numPermissions / 2), acc);
        uint256 newPermissionsLength = getAllPermissions().length;
        assertEq(newPermissionsLength, permissions.length - 1);

        // remove another Permission
        revokePermission(adminOp, acc);
        assertEq(getAllPermissions().length, --newPermissionsLength);

        // revoke the rest
        for (uint8 j = uint8(newPermissionsLength); j > 0; --j) {
            // check iter is not the first op to be revoked; j > 0 prevents re-revoking adminOp
            if (uint64(adminOp) + j == uint64(adminOp) + numPermissions / 2) continue;

            revokePermission(bytes8(uint64(adminOp) + j), acc);
        }
    }

    function test_revokePermissionRevertPermissionDoesNotExist(
        bytes8 operation, 
        bytes8 operation2,
        address acc,
        address acc2 
    ) public {
        vm.assume(acc != acc2); // either operations or accounts may collide but not both

        // add permissions
        grantPermission(operation, acc);
        grantPermission(operation2, acc2);

        // revoke them, twice
        revokePermission(operation, acc);
        err = abi.encodeWithSelector(PermissionDoesNotExist.selector, operation, acc);
        vm.expectRevert(err);
        revokePermission(operation, acc);

        revokePermission(operation2, acc2);
        err = abi.encodeWithSelector(PermissionDoesNotExist.selector, operation2, acc2);
        vm.expectRevert(err);
        revokePermission(operation2, acc2);
    }

    // function test_renouncePermission(address acc, uint8 numPermissions) public {
    //     vm.assume(numPermissions > 0);
    //     vm.assume(acc != address(0x0));

    //     // add permissions for acc
    //     for (uint256 i; i < numPermissions; ++i) {
    //         grantPermission(bytes8(uint64(adminOp) + uint64(i)), acc);
    //     }

    //     assertEq(getAllPermissions().length, numPermissions);

    //     // acc doesn't want them, renounces
    //     vm.startPrank(acc);
    //     renouncePermission(adminOp);
    //     assertEq(getAllPermissions().length, numPermissions - 1);
    // }

    // function test_renouncePermissionRevertPermissionDoesNotExist() public {}

    /*==============
        OVERRIDES
    ==============*/

    function _checkCanUpdatePermissions() internal override {}
}