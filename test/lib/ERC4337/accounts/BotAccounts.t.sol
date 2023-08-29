// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {BotAccounts} from "src/lib/ERC4337/accounts/BotAccounts.sol";
import {Operations} from "src/lib/Operations.sol";
import {IERC1271} from "openzeppelin-contracts/interfaces/IERC1271.sol";
import {IOwnableInternal} from "src/access/ownable/interface/IOwnable.sol";
import {IPermissions, IPermissionsInternal} from "src/access/permissions/interface/IPermissions.sol";
import {IGuards} from "src/guard/interface/IGuards.sol";
import {IExtensions} from "src/extension/interface/IExtensions.sol";

contract AccountsTest is Test {

    BotAccounts public botAccounts;

    address public entryPointAddress;
    address public owner;
    address public testTurnkey;
    bytes32 public digest;

    // intended to contain custom error signatures
    bytes public err;

    function setUp() public {
        // use actual EntryPoint deployment address
        entryPointAddress = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;
        owner = vm.addr(0xbeefEEbabe);
        testTurnkey = vm.addr(0xc0ffEEbabe);
        digest = bytes32(hex'beefEEbabe');
        address[] memory initArray = new address[](1);
        initArray[0] = testTurnkey;

        botAccounts = new BotAccounts(entryPointAddress, owner, initArray);
    }

    function test_setUp() public {
        assertEq(botAccounts.owner(), owner);
        
        assertTrue(botAccounts.supportsInterface(type(IERC1271).interfaceId));
        assertTrue(botAccounts.supportsInterface(botAccounts.erc165Id()));
        assertTrue(botAccounts.supportsInterface(type(IPermissions).interfaceId));
        assertTrue(botAccounts.supportsInterface(type(IGuards).interfaceId));
        assertTrue(botAccounts.supportsInterface(type(IExtensions).interfaceId));
 
        assertTrue(botAccounts.hasPermission(Operations.EXECUTE_PERMIT, testTurnkey));
    }

    function test_isValidSignature(uint256 startingPrivateKey, uint8 numPrivateKeys) public {
        address[] memory newTurnkeys = new address[](numPrivateKeys);

        address currentAddr;
        bytes[] memory rsvArray = new bytes[](numPrivateKeys);
        for (uint8 i; i < numPrivateKeys; ++i) {
            // private keys must be nonzero and less than the secp256k curve order
            vm.assume(startingPrivateKey != 0);
            vm.assume(startingPrivateKey < 0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFE_BAAEDCE6_AF48A03B_BFD25E8C_D0364141);
            
            uint256 currentPrivateKey = startingPrivateKey + i;
            currentAddr = vm.addr(currentPrivateKey);
            newTurnkeys[i] = currentAddr;
            
            vm.prank(owner);
            botAccounts.addPermission(Operations.EXECUTE_PERMIT, currentAddr);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(currentPrivateKey, digest);
            bytes memory currentRSV = abi.encodePacked(r, s, v);
            
            assertEq(currentRSV.length, 65);

            rsvArray[i] = currentRSV;
        }

        for (uint8 j; j < numPrivateKeys; ++j) {
            bytes4 eip1271ActualVal = 0x1626ba7e;
            bytes4 eip1271RetVal = botAccounts.isValidSignature(digest, rsvArray[j]);
            assertEq(eip1271RetVal, eip1271ActualVal);
        }
    }

    function test_addTurnkey(uint256 startingPrivateKey, uint8 numPrivateKeys) public {
        address[] memory newTurnkeys = new address[](numPrivateKeys);
        bytes8 op = Operations.EXECUTE_PERMIT;

        address currentAddr;
        for (uint8 i; i < numPrivateKeys; ++i) {
            // private keys must be nonzero and less than the secp256k curve order
            vm.assume(startingPrivateKey != 0);
            vm.assume(startingPrivateKey < 0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFE_BAAEDCE6_AF48A03B_BFD25E8C_D0364141 - numPrivateKeys);
            
            currentAddr = vm.addr(startingPrivateKey + i);
            newTurnkeys[i] = currentAddr;
            vm.prank(owner);
            botAccounts.addPermission(op, currentAddr);
        }

        for (uint256 j; j < newTurnkeys.length; ++j) {
            currentAddr = newTurnkeys[j];
            assertTrue(botAccounts.hasPermission(op, currentAddr));
        }

        // extra permission is due to testTurnkey added in setUp()
        assertEq(botAccounts.getAllPermissions().length, uint256(numPrivateKeys) + 1);
    }

    function test_addTurnkeyRevertPermissionDoesNotExist(address someAddress) public {
        err = abi.encodeWithSelector(IPermissionsInternal.PermissionDoesNotExist.selector, Operations.PERMISSIONS, address(this));
        vm.expectRevert(err);
        botAccounts.addPermission(Operations.EXECUTE_PERMIT, someAddress);
    }

    function test_removeTurnkey(uint256 startingPrivateKey, uint8 numPrivateKeys) public {
        address[] memory newTurnkeys = new address[](numPrivateKeys);
        bytes8 op = Operations.EXECUTE_PERMIT;

        address currentAddr;
        for (uint8 i; i < numPrivateKeys; ++i) {
            // private keys must be nonzero and less than the secp256k curve order
            vm.assume(startingPrivateKey != 0);
            vm.assume(startingPrivateKey < 0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFE_BAAEDCE6_AF48A03B_BFD25E8C_D0364141 - numPrivateKeys);
            
            currentAddr = vm.addr(startingPrivateKey + i);
            newTurnkeys[i] = currentAddr;
            vm.prank(owner);
            botAccounts.addPermission(op, currentAddr);
        }

        for (uint256 j; j < newTurnkeys.length; ++j) {
            currentAddr = newTurnkeys[j];
            assertTrue(botAccounts.hasPermission(op, currentAddr));

            vm.prank(owner);
            botAccounts.removePermission(op, currentAddr);

            assertFalse(botAccounts.hasPermission(op, currentAddr));
        }

        // extra permission is due to testTurnkey added in setUp()
        assertEq(botAccounts.getAllPermissions().length, 1);

        vm.prank(owner);
        botAccounts.removePermission(op, testTurnkey);
        assertEq(botAccounts.getAllPermissions().length, 0);
    }

    function test_removeTurnkeyRevertPermissionDoesNotExist(address someAddress) public {
        bytes8 op = Operations.EXECUTE_PERMIT;
        vm.prank(owner);
        botAccounts.addPermission(op, someAddress);

        // attempt removal of added permission without pranking owner
        err = abi.encodeWithSelector(IPermissionsInternal.PermissionDoesNotExist.selector, Operations.PERMISSIONS, address(this));
        vm.expectRevert(err);
        botAccounts.removePermission(op, someAddress);
    }
}