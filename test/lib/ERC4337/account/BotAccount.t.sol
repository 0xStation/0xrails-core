// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import "forge-std/console2.sol";
import {TurnkeyValidator} from "src/validator/TurnkeyValidator.sol";
import {BotAccount} from "src/lib/ERC4337/account/BotAccount.sol";
import {AccountFactory} from "src/lib/ERC4337/account/factory/AccountFactory.sol";
import {IAccountFactory} from "src/lib/ERC4337/account/factory/IAccountFactory.sol";
import {Operations} from "src/lib/Operations.sol";
import {UserOperation} from "src/lib/ERC4337/utils/UserOperation.sol";
import {IERC1271} from "openzeppelin-contracts/interfaces/IERC1271.sol";
import {IOwnableInternal} from "src/access/ownable/interface/IOwnable.sol";
import {IPermissions, IPermissionsInternal} from "src/access/permissions/interface/IPermissions.sol";
import {IGuards} from "src/guard/interface/IGuards.sol";
import {IExtensions} from "src/extension/interface/IExtensions.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract AccountTest is Test {

    BotAccount public botAccountImpl;
    BotAccount public botAccount;
    TurnkeyValidator public turnkeyValidator;
    AccountFactory public accountFactoryImpl;
    AccountFactory public accountFactoryProxy;

    address public entryPointAddress;
    address public owner;
    address public testTurnkey;
    UserOperation public userOp;
    bytes32 public userOpHash;
    bytes32 public salt;
    bytes public accountFactoryInitData;

    // intended to contain custom error signatures
    bytes public err;

    function setUp() public {
        // use actual EntryPoint deployment address
        entryPointAddress = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;
        owner = vm.addr(0xbeefEEbabe);
        testTurnkey = vm.addr(0xc0ffEEbabe);
        turnkeyValidator = new TurnkeyValidator(entryPointAddress);
        address[] memory turnkeyArray = new address[](1);
        turnkeyArray[0] = testTurnkey;
        userOp = UserOperation({
            sender: testTurnkey,
            nonce: 0,
            initCode: '',
            callData: '',
            callGasLimit: 0,
            verificationGasLimit: 0,
            preVerificationGas: 0,
            maxFeePerGas: 0,
            maxPriorityFeePerGas: 0,
            paymasterAndData: '',
            signature: ''
        });
        userOpHash = turnkeyValidator.getUserOpHash(userOp);
        salt = bytes32('garlicsalt');

        botAccountImpl = new BotAccount(entryPointAddress);
        accountFactoryImpl = new AccountFactory();
        accountFactoryInitData = abi.encodeWithSelector(
            AccountFactory.initialize.selector, 
            address(botAccountImpl), 
            owner 
        );
        accountFactoryProxy = AccountFactory(address(new ERC1967Proxy(address(accountFactoryImpl), accountFactoryInitData)));
        botAccount = BotAccount(payable(accountFactoryProxy.createBotAccount(
            salt, 
            owner,
            address(turnkeyValidator), 
            turnkeyArray
        )));
    }

    function test_setUp() public {
        assertEq(botAccount.entryPoint(), entryPointAddress);
        assertEq(botAccount.owner(), owner);
        assertEq(accountFactoryProxy.getAllAccountImpls().length, 3);
        assertEq(accountFactoryProxy.getAccountImpl(IAccountFactory.AccountType.BOT), address(botAccountImpl));
        
        assertTrue(botAccount.supportsInterface(type(IERC1271).interfaceId));
        assertTrue(botAccount.supportsInterface(botAccount.erc165Id()));
        assertTrue(botAccount.supportsInterface(type(IPermissions).interfaceId));
        assertTrue(botAccount.supportsInterface(type(IGuards).interfaceId));
        assertTrue(botAccount.supportsInterface(type(IExtensions).interfaceId));
 
        assertTrue(botAccount.hasPermission(Operations.CALL_PERMIT, testTurnkey));
    }

    function test_isValidSignature(uint256 startingPrivateKey, uint8 numPrivateKeys) public {
        userOpHash = turnkeyValidator.getUserOpHash(userOp);
        address[] memory newTurnkeys = new address[](numPrivateKeys);

        address currentAddr;
        bytes[] memory formattedSignatures = new bytes[](numPrivateKeys);
        for (uint8 i; i < numPrivateKeys; ++i) {
            // private keys must be nonzero and less than the secp256k curve order
            vm.assume(startingPrivateKey != 0);
            vm.assume(startingPrivateKey < 0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFE_BAAEDCE6_AF48A03B_BFD25E8C_D0364141);
            
            uint256 currentPrivateKey = startingPrivateKey + i;
            currentAddr = vm.addr(currentPrivateKey);
            newTurnkeys[i] = currentAddr;
            
            vm.prank(owner);
            botAccount.addPermission(Operations.CALL_PERMIT, currentAddr);

            (uint8 v, bytes32 r, bytes32 s) = vm.sign(currentPrivateKey, userOpHash);
            bytes memory currentRSV = abi.encodePacked(r, s, v);
            assertEq(currentRSV.length, 65);

            // ModularValidation schema developed by GroupOS requires prepended validator & signer addresses
            // note: `abi.encode` must be used to craft the signature or decoding will fail
            // ie: `abi.encodePacked(validator, currentAddr, currentRSV)` cannot be decoded
            bytes memory formattedSig = abi.encode(address(turnkeyValidator), currentAddr, currentRSV);
            
            formattedSignatures[i] = formattedSig;
        }

        for (uint8 j; j < numPrivateKeys; ++j) {
            bytes4 eip1271ActualVal = 0x1626ba7e;
            bytes4 eip1271RetVal = botAccount.isValidSignature(userOpHash, formattedSignatures[j]);
            assertEq(eip1271RetVal, eip1271ActualVal);
        }
    }

    function test_validateUserOp(uint256 startingPrivateKey, uint8 numPrivateKeys) public {
        uint256 missingAccountFunds = 0;
        address[] memory newTurnkeys = new address[](numPrivateKeys);

        address currentAddr;
        bytes[] memory formattedSignatures = new bytes[](numPrivateKeys);
        for (uint8 i; i < numPrivateKeys; ++i) {
            // private keys must be nonzero and less than the secp256k curve order
            vm.assume(startingPrivateKey != 0);
            vm.assume(startingPrivateKey < 0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFE_BAAEDCE6_AF48A03B_BFD25E8C_D0364141);
            
            uint256 currentPrivateKey = startingPrivateKey + i;
            currentAddr = vm.addr(currentPrivateKey);
            newTurnkeys[i] = currentAddr;
            
            vm.prank(owner);
            botAccount.addPermission(Operations.CALL_PERMIT, currentAddr);

            (uint8 v, bytes32 r, bytes32 s) = vm.sign(currentPrivateKey, userOpHash);
            bytes memory currentRSV = abi.encodePacked(r, s, v);
            assertEq(currentRSV.length, 65);

            // ModularValidation schema developed by GroupOS requires prepended validator & signer addresses
            // note: `abi.encode` must be used to craft the signature or decoding will fail
            // ie: `abi.encodePacked(validator, currentAddr, currentRSV)` cannot be decoded
            bytes memory formattedSig = abi.encode(address(turnkeyValidator), currentAddr, currentRSV);

            formattedSignatures[i] = formattedSig;
        }

        for (uint8 j; j < numPrivateKeys; ++j) {
            uint256 expectedValidationData = 0;

            // populate preexisting UserOperation `userOp` with formatted signature to be validated
            userOp.signature = formattedSignatures[j];
            vm.prank(entryPointAddress);
            uint256 returnedValidationData = botAccount.validateUserOp(userOp, userOpHash, missingAccountFunds);
            assertEq(returnedValidationData, expectedValidationData);
        }
    }

    function test_addTurnkey(uint256 startingPrivateKey, uint8 numPrivateKeys) public {
        address[] memory newTurnkeys = new address[](numPrivateKeys);
        bytes8 op = Operations.CALL_PERMIT;

        address currentAddr;
        for (uint8 i; i < numPrivateKeys; ++i) {
            // private keys must be nonzero and less than the secp256k curve order
            vm.assume(startingPrivateKey != 0);
            vm.assume(startingPrivateKey < 0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFE_BAAEDCE6_AF48A03B_BFD25E8C_D0364141 - numPrivateKeys);
            
            currentAddr = vm.addr(startingPrivateKey + i);
            newTurnkeys[i] = currentAddr;
            vm.prank(owner);
            botAccount.addPermission(op, currentAddr);
        }

        for (uint256 j; j < newTurnkeys.length; ++j) {
            currentAddr = newTurnkeys[j];
            assertTrue(botAccount.hasPermission(op, currentAddr));
        }

        // extra permission is due to testTurnkey added in setUp()
        assertEq(botAccount.getAllPermissions().length, uint256(numPrivateKeys) + 1);
    }

    function test_addTurnkeyRevertPermissionDoesNotExist(address someAddress) public {
        err = abi.encodeWithSelector(IPermissionsInternal.PermissionDoesNotExist.selector, Operations.PERMISSIONS, address(this));
        vm.expectRevert(err);
        botAccount.addPermission(Operations.CALL_PERMIT, someAddress);
    }

    function test_removeTurnkey(uint256 startingPrivateKey, uint8 numPrivateKeys) public {
        address[] memory newTurnkeys = new address[](numPrivateKeys);
        bytes8 op = Operations.CALL_PERMIT;

        address currentAddr;
        for (uint8 i; i < numPrivateKeys; ++i) {
            // private keys must be nonzero and less than the secp256k curve order
            vm.assume(startingPrivateKey != 0);
            vm.assume(startingPrivateKey < 0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFE_BAAEDCE6_AF48A03B_BFD25E8C_D0364141 - numPrivateKeys);
            
            currentAddr = vm.addr(startingPrivateKey + i);
            newTurnkeys[i] = currentAddr;
            vm.prank(owner);
            botAccount.addPermission(op, currentAddr);
        }

        for (uint256 j; j < newTurnkeys.length; ++j) {
            currentAddr = newTurnkeys[j];
            assertTrue(botAccount.hasPermission(op, currentAddr));

            vm.prank(owner);
            botAccount.removePermission(op, currentAddr);

            assertFalse(botAccount.hasPermission(op, currentAddr));
        }

        // extra permission is due to testTurnkey added in setUp()
        assertEq(botAccount.getAllPermissions().length, 1);

        vm.prank(owner);
        botAccount.removePermission(op, testTurnkey);
        assertEq(botAccount.getAllPermissions().length, 0);
    }

    function test_removeTurnkeyRevertPermissionDoesNotExist(address someAddress) public {
        bytes8 op = Operations.CALL_PERMIT;
        vm.prank(owner);
        botAccount.addPermission(op, someAddress);

        // attempt removal of added permission without pranking owner
        err = abi.encodeWithSelector(IPermissionsInternal.PermissionDoesNotExist.selector, Operations.PERMISSIONS, address(this));
        vm.expectRevert(err);
        botAccount.removePermission(op, someAddress);
    }
}