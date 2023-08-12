// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Access} from "src/access/Access.sol";
import {PermissionsStorage} from "src/access/permissions/PermissionsStorage.sol";
import {Operations} from "src/lib/Operations.sol";

contract AccessTest is Test, Access {
    bytes8[] supportedOps;

    // to store errors
    bytes err;

    function setUp() public {
        supportedOps.push(Operations.ADMIN);
        supportedOps.push(Operations.MINT);
        supportedOps.push(Operations.BURN);
        supportedOps.push(Operations.TRANSFER);
        supportedOps.push(Operations.METADATA);
    }

    function test_hasPermissionOperation(address account, uint8 _variant) public {
        address unpermittedAddress = address(0xbeefEbabe);
        vm.assume(account != unpermittedAddress);

        PermissionsStorage.OperationVariant variant = PermissionsStorage.OperationVariant(_variant % 3 );

        // grant each operation and assert checks
        for (uint256 i; i < supportedOps.length; ++i) {
            bytes8 currentOp = supportedOps[i];
            setPermission(currentOp, variant, account);
            assertTrue(hasPermission(currentOp, variant, account));

            // assert unpermittedAddress returns false
            assertFalse(hasPermission(currentOp, variant, unpermittedAddress));
        }
    }

    function test_hasPermissionAdmin(address account) public {
        address unpermittedAddress = address(0xbeefEbabe);
        vm.assume(account != unpermittedAddress);

        // grant admin operation and assert checks
        bytes8 adminOp = supportedOps[0];
        setPermission(adminOp, PermissionsStorage.OperationVariant.EXECUTE, account);
        assertTrue(hasPermission(adminOp, PermissionsStorage.OperationVariant.EXECUTE, account));

        // assert unpermittedAddress returns false
        assertFalse(hasPermission(adminOp, PermissionsStorage.OperationVariant.EXECUTE, unpermittedAddress));
    }

    function test_hasPermissionOwner(bytes8 randomOp) public {
        // owner() override set in this test file results in `owner == address(0x0)`
        assertEq(owner(), address(0x0));

        for (uint256 i; i < supportedOps.length; ++i) {
            bytes8 currentOp = supportedOps[i];
            assertTrue(hasPermission(currentOp, PermissionsStorage.OperationVariant.EXECUTE, owner()));
        }

        assertTrue(hasPermission(randomOp, PermissionsStorage.OperationVariant.EXECUTE, owner()));
    }

    /*==============
        OVERRIDES
    ==============*/

    // returns address(0x0)
    function owner() public view override returns (address) {}
    function _checkCanUpdatePermissions() internal override {}
}
