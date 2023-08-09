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

    /*==============
        OVERRIDES
    ==============*/

    function _checkCanUpdatePermissions() internal override {}
}