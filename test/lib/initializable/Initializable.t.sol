// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Initializable} from "src/lib/initializable/Initializable.sol";
import {InitializableStorage} from "src/lib/initializable/InitializableStorage.sol";
import {ERC721Rails} from "src/cores/ERC721/ERC721Rails.sol";

contract InitializableTest is Test {
    ERC721Rails public implementation;
    ERC721Rails public proxy; // ERC1967 proxy wrapped in ERC721Rails for convenience
    address public owner;
    string public name;
    string public symbol;

    // to store errors
    bytes err;

    // errors
    error AlreadyInitialized();
    error OwnerUnauthorizedAccount(address notOwner);
    error PermissionDoesNotExist(bytes4 operation, address account);

    function setUp() public {
        // deploy and initialize erc721
        owner = address(0xbeefEbabe);
        name = "BeefEBabe";
        symbol = "BEEF";
        implementation = new ERC721Rails();
        bytes memory initializeData = abi.encodeWithSelector(ERC721Rails.initialize.selector, owner, name, symbol, "");
        proxy = ERC721Rails(payable(address(new ERC1967Proxy(address(implementation), initializeData))));
    }

    function test_setUp() public {
        // assert proxy initialized
        assertEq(proxy.owner(), owner);
        assertEq(proxy.name(), name);
        assertEq(proxy.symbol(), symbol);
        assertTrue(proxy.initialized());

        // assert implementation initialized but did not receive state updates
        assertEq(implementation.owner(), address(0x0));
        assertEq(implementation.name(), "");
        assertEq(implementation.symbol(), "");
        assertTrue(implementation.initialized());
    }

    function test_initialize() public {
        // initialize new membership
        bytes memory newInitializeData =
            abi.encodeWithSelector(ERC721Rails.initialize.selector, owner, name, symbol, "");
        ERC721Rails newProxy =
            ERC721Rails(payable(address(new ERC1967Proxy(address(implementation), newInitializeData))));

        assertEq(newProxy.owner(), owner);
        assertEq(newProxy.name(), name);
        assertEq(newProxy.symbol(), symbol);
        assertTrue(newProxy.initialized());
    }

    function test_initializeRevertAlreadyInitialized() public {
        // expect AlreadyInitialized() error when calling initialize on already-initialized proxy
        err = abi.encodeWithSelector(AlreadyInitialized.selector);
        vm.expectRevert(err);
        proxy.initialize(owner, name, symbol, "");
    }

    function test_initializeImplementationRevertDisabled() public {
        bytes memory maliciousMintToCall = abi.encodeWithSelector(ERC721Rails.mintTo.selector, address(this), 42069);

        vm.expectRevert();
        implementation.initialize(address(this), "", "", maliciousMintToCall);
        assertEq(proxy.balanceOf(address(this)), 0);
    }

    function test_proxyRevertUnauthorized() public {
        // attempt unauthorized transferOwnership() call
        err = abi.encodeWithSelector(OwnerUnauthorizedAccount.selector, address(this));
        vm.expectRevert(err);
        bytes memory transferOwnerCall = abi.encodeWithSignature("transferOwnership(address)", address(this));
        (bool r,) = address(proxy).call(transferOwnerCall);
        assertTrue(r); // returns true, silence compiler

        // attempt on impl
        vm.expectRevert();
        implementation.initialize(address(this), "", "", transferOwnerCall);

        // attempt unauthorized transferOwnership() call nested within UUPS upgradeToAndCall()
        vm.expectRevert();
        bytes memory upgradeCall =
            abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(this), transferOwnerCall);
        (bool res,) = address(proxy).call(upgradeCall);
        assertTrue(res); // returns true, silence compiler

        // attempt on impl
        vm.expectRevert();
        implementation.initialize(address(this), "", "", upgradeCall);
    }
}
