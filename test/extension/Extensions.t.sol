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

    function test_setExtension(bytes4 selector) public returns(address) {
        // assert selector has not been extended
        assertFalse(hasExtended(selector));
        assertEq(getAllExtensions().length, 0);

        vm.expectEmit(true, true, false, true);
        emit ExtensionUpdated(selector, address(0x0), address(exampleExtension));
        setExtension(selector, address(exampleExtension));

        // assert state changes via getters
        assertTrue(hasExtended(selector));
        assertEq(extensionOf(selector), address(exampleExtension));
        Extension[] memory newExtensions = this.getAllExtensions();
        assertEq(newExtensions.length, 1);

        // check storage directly
        ExtensionsStorage.Layout storage layout = ExtensionsStorage.layout();
        uint256 numSelectors = layout._selectors.length;
        assertEq(numSelectors, 1);
        ExtensionsStorage.ExtensionData memory setExtension = layout._extensions[selector];
        assertEq(setExtension.index, 0);
        assertEq(setExtension.updatedAt, uint40(block.timestamp));
        assertEq(setExtension.implementation, address(exampleExtension));
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
        // enough access control?
    }


    /*==============
        OVERRIDES
    ==============*/

    function _checkCanUpdateExtensions() internal override {}
}
