// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IExtensionsExternal, IExtensions} from "./interface/IExtensions.sol";
import {ExtensionsInternal} from "./ExtensionsInternal.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";

abstract contract Extensions is ExtensionsInternal, IExtensionsExternal {
    /*==================
        CALL ROUTING
    ==================*/

    fallback() external payable virtual {
        address implementation = extensionOf(msg.sig);
        Address.functionDelegateCall(implementation, msg.data); // library checks for target contract existence
    }

    receive() external payable virtual {}

    /*===========
        VIEWS
    ===========*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IExtensions).interfaceId;
    }

    /*=============
        SETTERS
    =============*/

    function addExtension(bytes4 selector, address implementation) public virtual canUpdateExtensions {
        _addExtension(selector, implementation);
    }

    function removeExtension(bytes4 selector) public virtual canUpdateExtensions {
        _removeExtension(selector);
    }

    function updateExtension(bytes4 selector, address implementation) public virtual canUpdateExtensions {
        _updateExtension(selector, implementation);
    }

    /*===================
        AUTHORIZATION
    ===================*/

    modifier canUpdateExtensions() {
        _checkCanUpdateExtensions();
        _;
    }

    function _checkCanUpdateExtensions() internal virtual {}
}
