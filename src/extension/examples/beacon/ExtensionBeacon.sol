// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Extensions} from "../../Extensions.sol";
import {ExtensionsStorage} from "../../ExtensionsStorage.sol";
import {IExtensions} from "../../interface/IExtensions.sol";
import {IExtensionBeacon} from "./IExtensionBeacon.sol";
import {IExtension} from "../../interface/IExtension.sol";

abstract contract ExtensionBeacon is Extensions, IExtensionBeacon {
    /*===========
        VIEWS
    ===========*/

    function extensionOf(bytes4 selector, uint40 lastValidUpdatedAt)
        public
        view
        override
        returns (address implementation)
    {
        ExtensionsStorage.Layout storage layout = ExtensionsStorage.layout();
        ExtensionsStorage.ExtensionData memory extension = layout._extensions[selector];
        if (extension.implementation == address(0)) revert ExtensionDoesNotExist(selector);
        if (extension.updatedAt > lastValidUpdatedAt) {
            revert ExtensionUpdatedAfter(selector, extension.updatedAt, lastValidUpdatedAt);
        }
        return extension.implementation;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IExtensions).interfaceId || interfaceId == type(IExtensionBeacon).interfaceId;
    }
}
