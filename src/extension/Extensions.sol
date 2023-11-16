// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IExtensions} from "./interface/IExtensions.sol";
import {IExtension} from "./interface/IExtension.sol";
import {ExtensionsStorage} from "./ExtensionsStorage.sol";
import {Contract} from "../lib/Contract.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";

/// @title Extensions - A contract for managing contract extensions via function delegation
/// @notice This abstract contract provides functionality for extending function selectors using external contracts.
abstract contract Extensions is IExtensions {

    /*==================
        CALL ROUTING
    ==================*/

    /// @dev Fallback function to delegate calls to extension contracts.
    /// @param '' The data from which `msg.sig` and `msg.data` are grabbed to craft a delegatecall
    /// @return '' The return data from using delegatecall on the extension contract.
    fallback(bytes calldata) external payable virtual returns (bytes memory) {
        // Obtain the implementation address for the function selector.
        address implementation = extensionOf(msg.sig);
        // Delegate the call to the extension contract.
        return Address.functionDelegateCall(implementation, msg.data); // library checks for target contract existence
    }

    receive() external payable virtual {}

    /*===========
        VIEWS
    ===========*/

    /// @inheritdoc IExtensions
    function hasExtended(bytes4 selector) public view virtual override returns (bool) {
        ExtensionsStorage.Layout storage layout = ExtensionsStorage.layout();
        return layout._extensions[selector].implementation != address(0);
    }

    /// @inheritdoc IExtensions
    function extensionOf(bytes4 selector) public view virtual returns (address implementation) {
        ExtensionsStorage.Layout storage layout = ExtensionsStorage.layout();
        return layout._extensions[selector].implementation;
    }

    /// @inheritdoc IExtensions
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

    /// @dev Function to implement ERC-165 compliance 
    /// @param interfaceId The interface identifier to check.
    /// @return _ Boolean indicating whether the contract supports the specified interface.
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IExtensions).interfaceId;
    }

    /*=============
        SETTERS
    =============*/

    /// @dev Function to set an extension contract for a given selector.
    /// @param selector The function selector for which to add an extension contract.
    /// @param implementation The extension contract address containing code to extend a selector
    function setExtension(bytes4 selector, address implementation) public virtual canUpdateExtensions {
        _setExtension(selector, implementation);
    }

    /// @dev Function to remove an extension for a given selector.
    /// @param selector The function selector for which to remove its extension contract.
    function removeExtension(bytes4 selector) public virtual canUpdateExtensions {
        _removeExtension(selector);
    }

    /*===============
        INTERNALS
    ===============*/

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

    /*===================
        AUTHORIZATION
    ===================*/

    modifier canUpdateExtensions() {
        _checkCanUpdateExtensions();
        _;
    }

    /// @dev Function to check if caller possesses sufficient permission to set extensions
    /// @notice Should revert upon failure.
    function _checkCanUpdateExtensions() internal virtual;
}
