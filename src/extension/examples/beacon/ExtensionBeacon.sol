// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ExtensionRouter} from "../../ExtensionRouter.sol";
import {IExtensionRouter} from "../../interface/IExtensionRouter.sol";
import {IExtensionBeacon} from "./IExtensionBeacon.sol";
import {IExtension} from "../../interface/IExtension.sol";

abstract contract ExtensionBeacon is ExtensionRouter, IExtensionBeacon {
    /*===========
        VIEWS
    ===========*/

    function extensionOf(bytes4 selector, uint40 lastValidUpdatedAt)
        public
        view
        override
        returns (address implementation)
    {
        ExtensionData memory extension = _extensions[selector];
        if (extension.implementation == address(0)) revert SelectorNotExtended(selector);
        if (extension.info > lastValidUpdatedAt) {
            revert ExtensionUpdatedAfter(selector, uint40(extension.info), lastValidUpdatedAt);
        }
        return extension.implementation;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IExtensionRouter).interfaceId || interfaceId == type(IExtensionBeacon).interfaceId;
    }

    /*=============
        SETTERS
    =============*/

    function addExtension(bytes4 selector, address implementation) public override canUpdateExtensions {
        _addExtension(selector, implementation, uint40(block.timestamp));
    }

    function updateExtension(bytes4 selector, address implementation) public override canUpdateExtensions {
        _updateExtension(selector, implementation, uint40(block.timestamp));
    }
}
