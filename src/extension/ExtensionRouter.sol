// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IExtensionRouter} from "./interface/IExtensionRouter.sol";
import {IExtension} from "./interface/IExtension.sol";
import {Contract} from "src/lib/Contract.sol";

abstract contract ExtensionRouter is IExtensionRouter, Contract {
    bytes4[] internal _selectors;
    mapping(bytes4 => ExtensionData) internal _extensions;

    /*==================
        CALL ROUTING
    ==================*/

    fallback() external payable virtual {
        address implementation = extensionOf(msg.sig);
        _delegate(implementation);
    }

    receive() external payable virtual {}

    /// @dev delegateCalls an `implementation` smart contract.
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /*===========
        VIEWS
    ===========*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IExtensionRouter).interfaceId;
    }

    function hasExtended(bytes4 selector) public view virtual returns (bool) {
        return _extensions[selector].implementation != address(0);
    }

    function extensionOf(bytes4 selector) public view virtual returns (address implementation) {
        return _extensions[selector].implementation;
    }

    function getAllExtensions() public view virtual returns (Extension[] memory extensions) {
        uint256 len = _selectors.length;
        extensions = new Extension[](len);
        for (uint256 i; i < len; i++) {
            bytes4 selector = _selectors[i + 1];
            ExtensionData memory extension = _extensions[selector];
            extensions[i] = Extension(
                selector, extension.implementation, IExtension(extension.implementation).signatureOf(selector)
            );
        }
        return extensions;
    }

    /*=============
        SETTERS
    =============*/

    modifier canUpdateExtensions() {
        _checkCanUpdateExtensions();
        _;
    }

    function addExtension(bytes4 selector, address implementation) public virtual canUpdateExtensions {
        _addExtension(selector, implementation, 0);
    }

    function removeExtension(bytes4 selector) public virtual canUpdateExtensions {
        _removeExtension(selector);
    }

    function updateExtension(bytes4 selector, address implementation) public virtual canUpdateExtensions {
        _updateExtension(selector, implementation, 0);
    }

    /*===============
        INTERNALS
    ===============*/

    function _addExtension(bytes4 selector, address implementation, uint80 info) internal {
        _requireContract(implementation);
        ExtensionData memory oldExtension = _extensions[selector];
        if (oldExtension.implementation != address(0)) revert SelectorAlreadyExtended(selector);

        ExtensionData memory extension = ExtensionData(uint16(_selectors.length), implementation, info); // new length will be `len + 1`, so this extension has index `len`

        _extensions[selector] = extension;
        _selectors.push(selector); // set new selector at index and increment length

        emit Extend(selector, address(0), implementation);
    }

    function _removeExtension(bytes4 selector) internal {
        ExtensionData memory oldExtension = _extensions[selector];
        if (oldExtension.implementation == address(0)) revert SelectorNotExtended(selector);

        uint256 lastIndex = _selectors.length - 1;
        // if removing extension not at the end of the array, swap extension with last in array
        if (oldExtension.index < lastIndex) {
            bytes4 lastSelector = _selectors[lastIndex];
            ExtensionData memory lastExtension = _extensions[lastSelector];
            lastExtension.index = oldExtension.index;
            _extensions[lastSelector] = lastExtension;
            _selectors[oldExtension.index] = lastSelector;
        }
        delete _extensions[selector];
        _selectors.pop(); // delete extension in last index and decrement length

        emit Extend(selector, oldExtension.implementation, address(0));
    }

    function _updateExtension(bytes4 selector, address implementation, uint80 info) internal {
        _requireContract(implementation);
        ExtensionData memory oldExtension = _extensions[selector];
        if (implementation == oldExtension.implementation) {
            revert ExtensionUnchanged(oldExtension.implementation, implementation);
        }

        ExtensionData memory newExtension = ExtensionData(uint16(oldExtension.index), implementation, info);
        _extensions[selector] = newExtension;

        emit Extend(selector, oldExtension.implementation, implementation);
    }

    /*===================
        AUTHORIZATION
    ===================*/

    function _checkCanUpdateExtensions() internal virtual {}
}
