// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Extensions} from "src/extension/Extensions.sol";
import {IExtensions} from "src/extension/interface/IExtensions.sol";
import {ExtensionsInternal} from "src/extension/ExtensionsInternal.sol";
import {ExtensionsStorage} from "src/extension/ExtensionsStorage.sol";
import {ExtensionBeacon} from "src/extension/examples/beacon/ExtensionBeacon.sol";
import {Contract} from "src/lib/Contract.sol";

contract ExtensionsTest is Test, Extensions {

    ExampleExtension public exampleExtension;

    // to store expected revert errors
    bytes err;

    function setUp() public {
        exampleExtension = new ExampleExtension();
    }

    function test_setExtension(bytes4 selector) public {
        // assert selector has not been extended
        assertFalse(hasExtended(selector));
        assertEq(getAllExtensions().length, 0);

        vm.expectEmit(true, true, false, true);
        emit ExtensionUpdated(selector, address(0x0), address(exampleExtension));
        setExtension(selector, address(exampleExtension));

        // assert state changes via getters
        assertTrue(hasExtended(selector));
        assertEq(extensionOf(selector), address(exampleExtension));
        Extension[] memory newExtensions = getAllExtensions(); // layout._selectors[i + 1] causing revert
        // assertEq(newExtensions.length, 1);

        // // check storage directly
        // ExtensionsStorage.Layout storage layout = ExtensionsStorage.layout();
        // uint256 numSelectors = layout._selectors.length;
        // assertEq(numSelectors, 1);
    }

    function test_setExtensionRevertRequireContract(bytes4 selector) public {
        address notContract = address(0xbeefEbabe);
        err = abi.encodeWithSelector(Contract.InvalidContract.selector, notContract);
        vm.expectRevert(err);
        setExtension(selector, notContract);

        // assert no state changes
        assertFalse(hasExtended(selector));
        assertEq(getAllExtensions().length, 0);
    }

    function test_setExtensionRevertExtensionUnchanged() public {}

    function test_removeExtension() public {}

    function test_removeExtensionRevertExtensionDoesNotExist() public {}

    function test_fallback() public {
        // how does functionDelegateCall() respond to selfdestructed addresses
    }


    /*==============
        OVERRIDES
    ==============*/

    function _checkCanUpdateExtensions() internal override {}
}

contract ExampleExtension is ExtensionBeacon {

    /*==============
        OVERRIDES
    ==============*/

    function _checkCanUpdateExtensions() internal override {}
}