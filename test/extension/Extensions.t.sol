// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Extensions} from "src/extension/Extensions.sol";
import {IExtensions} from "src/extension/interface/IExtensions.sol";
import {IExtension} from "src/extension/interface/IExtension.sol";
import {ExtensionsInternal} from "src/extension/ExtensionsInternal.sol";
import {ExtensionsStorage} from "src/extension/ExtensionsStorage.sol";
import {MetadataRouterExtension} from "src/extension/examples/metadataRouter/MetadataRouterExtension.sol";
import {Contract} from "src/lib/Contract.sol";

contract ExtensionsTest is Test, Extensions {

    MetadataRouterExtension public exampleExtension;

    // to store expected revert errors
    bytes err;

    function setUp() public {
        exampleExtension = new MetadataRouterExtension();
    }

    function test_setExtension(bytes4 selector) public {
        // assert selector has not been extended
        assertFalse(hasExtended(selector));
        assertEq(getAllExtensions().length, 0);

        // add new extension
        vm.expectEmit(true, true, false, true);
        emit ExtensionUpdated(selector, address(0x0), address(exampleExtension));
        setExtension(selector, address(exampleExtension));

        // assert state changes via getters
        assertTrue(hasExtended(selector));
        assertEq(extensionOf(selector), address(exampleExtension));
        Extension[] memory newExtensions = this.getAllExtensions(); // calling externally for better stack traces
        assertEq(newExtensions.length, 1);
        assertEq(newExtensions[0].selector, selector);
        assertEq(newExtensions[0].implementation, address(exampleExtension));
        assertEq(newExtensions[0].updatedAt, uint40(block.timestamp));
        assertEq(newExtensions[0].signature, exampleExtension.signatureOf(selector));

        // check storage directly
        ExtensionsStorage.Layout storage layout = ExtensionsStorage.layout();
        uint256 numSelectors = layout._selectors.length;
        assertEq(numSelectors, 1);
        assertEq(layout._selectors[0], selector);
        ExtensionsStorage.ExtensionData memory storedExtension = layout._extensions[selector];
        assertEq(storedExtension.index, 0);
        assertEq(storedExtension.updatedAt, uint40(block.timestamp));
        assertEq(storedExtension.implementation, address(exampleExtension));

        // update existing extension to another extension
        MetadataRouterExtension otherExtension = new MetadataRouterExtension();
        setExtension(selector, address(otherExtension));

        // assert state changes via getters
        assertTrue(hasExtended(selector));
        assertEq(extensionOf(selector), address(otherExtension));
        Extension[] memory updatedExtensions = this.getAllExtensions();
        assertEq(updatedExtensions.length, 1);
        assertEq(updatedExtensions[0].selector, selector);
        assertEq(updatedExtensions[0].implementation, address(otherExtension));
        assertEq(updatedExtensions[0].updatedAt, uint40(block.timestamp));
        assertEq(updatedExtensions[0].signature, otherExtension.signatureOf(selector));

        // check storage directly
        assertEq(layout._selectors.length, 1);
        assertEq(layout._selectors[0], selector);
        ExtensionsStorage.ExtensionData memory newStoredExtension = layout._extensions[selector];
        assertEq(newStoredExtension.index, 0);
        assertEq(newStoredExtension.updatedAt, uint40(block.timestamp));
        assertEq(newStoredExtension.implementation, address(otherExtension));
    }

    function test_setExtensionRevertRequireContract(bytes4 selector) public {
        address notContract = address(0xbeefEbabe);
        err = abi.encodeWithSelector(Contract.InvalidContract.selector, notContract);
        vm.expectRevert(err);
        setExtension(selector, notContract);

        // assert no state changes
        assertFalse(hasExtended(selector));
        assertEq(getAllExtensions().length, 0);
        ExtensionsStorage.Layout storage layout = ExtensionsStorage.layout();
        assertEq(layout._selectors.length, 0);

        ExtensionsStorage.ExtensionData memory newStoredExtension = layout._extensions[selector];
        assertEq(newStoredExtension.index, 0);
        assertEq(newStoredExtension.updatedAt, 0);
        assertEq(newStoredExtension.implementation, address(0x0));
    }

    function test_setExtensionRevertExtensionUnchanged(bytes4 selector) public {
        // add new extension
        vm.expectEmit(true, true, false, true);
        emit ExtensionUpdated(selector, address(0x0), address(exampleExtension));
        setExtension(selector, address(exampleExtension));

        // attempt to update existing extension to same extension
        err = abi.encodeWithSelector(ExtensionUnchanged.selector, selector, address(exampleExtension), address(exampleExtension));
        vm.expectRevert(err);
        setExtension(selector, address(exampleExtension));

        // assert state remains as expected
        assertTrue(hasExtended(selector));
        assertEq(extensionOf(selector), address(exampleExtension));
        Extension[] memory updatedExtensions = this.getAllExtensions();
        assertEq(updatedExtensions.length, 1);
        assertEq(updatedExtensions[0].selector, selector);
        assertEq(updatedExtensions[0].implementation, address(exampleExtension));
        assertEq(updatedExtensions[0].updatedAt, uint40(block.timestamp));
        assertEq(updatedExtensions[0].signature, exampleExtension.signatureOf(selector));
    }

    function test_removeExtension(bytes4 selector, uint8 numExtensions) public {
        // assert selector has not been extended
        assertFalse(hasExtended(selector));
        assertEq(getAllExtensions().length, 0);

        // add new extensions
        for (uint8 i; i < numExtensions; ++i) {
            bytes4 currentSelector = bytes4(uint32(selector) + i);
            setExtension(currentSelector, address(exampleExtension));

            // assert extension was set 
            assertTrue(hasExtended(currentSelector));
            assertEq(extensionOf(currentSelector), address(exampleExtension));
        }

        // check array length
        Extension[] memory newExtensions = this.getAllExtensions();
        assertEq(newExtensions.length, numExtensions);

        ExtensionsStorage.Layout storage layout = ExtensionsStorage.layout();
        for (uint8 j; j < numExtensions; ++j) {
            // check all added correctly then remove
            bytes4 jSelector = bytes4(uint32(selector) + j);
            assertEq(newExtensions[j].selector, jSelector);
            assertEq(newExtensions[j].implementation, address(exampleExtension));
            assertEq(newExtensions[j].updatedAt, uint40(block.timestamp));
            assertEq(newExtensions[j].signature, exampleExtension.signatureOf(jSelector));

            // remove extensions
            removeExtension(jSelector);

            // check removal of specific selector
            assertFalse(hasExtended(jSelector));
            assertEq(extensionOf(jSelector), address(0x0));
            ExtensionsStorage.ExtensionData memory newStoredExtension = layout._extensions[jSelector];
            assertEq(newStoredExtension.index, 0);
            assertEq(newStoredExtension.updatedAt, 0);
            assertEq(newStoredExtension.implementation, address(0x0));
        }

        // assert extensions were all removed from arrays
        Extension[] memory removedExtensions = this.getAllExtensions();
        assertEq(removedExtensions.length, 0);
        assertEq(layout._selectors.length, 0);
    }

    function test_removeExtensionRevertExtensionDoesNotExist(bytes4 selector, uint32 numReverts) public {
        for (uint32 i; i < numReverts; ++i) {
            bytes4 currentSelector = bytes4(uint32(selector) + i);

            // assert current selector has not been extended
            assertFalse(hasExtended(currentSelector));
            assertEq(getAllExtensions().length, 0);

            // attempt to remove nonexistent extensions
            err = abi.encodeWithSelector(ExtensionDoesNotExist.selector, currentSelector);
            vm.expectRevert(err);
            removeExtension(currentSelector);

            // reassert no state changes
            assertFalse(hasExtended(currentSelector));
            assertEq(getAllExtensions().length, 0);
        }
    }

    /*==============
        OVERRIDES
    ==============*/

    function _checkCanUpdateExtensions() internal override {}
}

// Test for self destructing MaliciousExtension contract extracted into its own scope for cleanliness
contract MaliciousExtensionsTest is Test, Extensions {

    MetadataRouterExtension public exampleExtension;
    MaliciousExtension public maliciousExtension;

    bytes4 someSelector;

    function setUp() public {
        exampleExtension = new MetadataRouterExtension();

        // deploy and selfdestruct() extension for testing fallback
        maliciousExtension = new MaliciousExtension();
        someSelector = MetadataRouterExtension.getAllSelectors.selector;
        setExtension(someSelector, address(maliciousExtension));
        maliciousExtension.selfDestruct();
    }

    function test_fallbackSelfdestruct() public {
        // test functionDelegateCall() with selfdestructed address
        // assert maliciousExtension has been selfdestructed
        uint256 a;
        address addr = address(maliciousExtension);
        assembly{
            a := extcodesize(addr)
        }
        assertEq(a, 0);

        // all calls to functions with selector pointing to selfdestructed address now revert
        // not an issue since setting implementation involved access control in the first place
        // and unrecognized function signatures result in delegation to address(0x0) which revert
        bytes memory payload = abi.encodeWithSelector(someSelector);
        (bool r,) = address(this).call(payload);
        require(r);

        // can still remove or update to a new implementation
        removeExtension(someSelector);
        setExtension(someSelector, address(exampleExtension));
    }

    /*==============
        OVERRIDES
    ==============*/

    function _checkCanUpdateExtensions() internal override {}
}

contract MaliciousExtension is MetadataRouterExtension {
    function selfDestruct() public {
        selfdestruct(payable(address(0x0)));
    }
}
