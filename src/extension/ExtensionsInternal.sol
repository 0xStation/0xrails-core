// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IExtensions} from "./interface/IExtensions.sol";
import {IExtension} from "./interface/IExtension.sol";
import {ExtensionsStorage} from "./ExtensionsStorage.sol";
import {Contract} from "../lib/Contract.sol";

abstract contract ExtensionsInternal is IExtensions {
    /*===========
        VIEWS
    ===========*/

    function hasExtended(bytes4 selector) public view virtual returns (bool) {
        ExtensionsStorage.Layout storage layout = ExtensionsStorage.layout();
        return layout._extensions[selector].implementation != address(0);
    }

    function extensionOf(bytes4 selector) public view virtual returns (address implementation) {
        ExtensionsStorage.Layout storage layout = ExtensionsStorage.layout();
        return layout._extensions[selector].implementation;
    }

    function getAllExtensions() public view virtual returns (Extension[] memory extensions) {
        ExtensionsStorage.Layout storage layout = ExtensionsStorage.layout();
        uint256 len = layout._selectors.length;
        extensions = new Extension[](len);
        for (uint256 i; i < len; i++) {
            bytes4 selector = layout._selectors[i];
            ExtensionsStorage.ExtensionData memory extension = layout._extensions[selector];
            extensions[i] = Extension(
                selector,
                extension.implementation,
                extension.updatedAt,
                IExtension(extension.implementation).signatureOf(selector)
            );
        }
        return extensions;
    }

    /*=============
        SETTERS
    =============*/

    function _setExtension(bytes4 selector, address implementation) internal {
        ExtensionsStorage.Layout storage layout = ExtensionsStorage.layout();
        Contract._requireContract(implementation);
        ExtensionsStorage.ExtensionData memory oldExtension = layout._extensions[selector];
        address oldImplementation = oldExtension.implementation;
        if (oldImplementation != address(0)) {
            // update existing Extension, reverting if `implementation` is unchanged
            if (implementation == oldImplementation) {
                revert ExtensionUnchanged(selector, oldImplementation, implementation);
            }

            // update only necessary struct members to save on SSTOREs
            layout._extensions[selector].updatedAt = uint40(block.timestamp);
            layout._extensions[selector].implementation = implementation;
        } else {
            // add new Extension
            // new length will be `len + 1`, so this extension has index `len`
            ExtensionsStorage.ExtensionData memory extension = ExtensionsStorage.ExtensionData(
                uint24(layout._selectors.length), uint40(block.timestamp), implementation
            );

            layout._extensions[selector] = extension;
            layout._selectors.push(selector); // set new selector at index and increment length
        }

        emit ExtensionUpdated(selector, oldImplementation, implementation);
    }

    function _removeExtension(bytes4 selector) internal {
        ExtensionsStorage.Layout storage layout = ExtensionsStorage.layout();
        ExtensionsStorage.ExtensionData memory oldExtension = layout._extensions[selector];
        if (oldExtension.implementation == address(0)) revert ExtensionDoesNotExist(selector);

        uint256 lastIndex = layout._selectors.length - 1;
        // if removing extension not at the end of the array, swap extension with last in array
        if (oldExtension.index < lastIndex) {
            bytes4 lastSelector = layout._selectors[lastIndex];
            ExtensionsStorage.ExtensionData memory lastExtension = layout._extensions[lastSelector];
            lastExtension.index = oldExtension.index;
            layout._selectors[oldExtension.index] = lastSelector;
            layout._extensions[lastSelector] = lastExtension;
        }
        delete layout._extensions[selector];
        layout._selectors.pop(); // delete extension in last index and decrement length

        emit ExtensionUpdated(selector, oldExtension.implementation, address(0));
    }
}
