// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IExtensions} from "./interface/IExtensions.sol";
import {ExtensionsInternal} from "./ExtensionsInternal.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";

abstract contract Extensions is ExtensionsInternal {
    /*==================
        CALL ROUTING
    ==================*/

    fallback(bytes calldata) external payable virtual returns (bytes memory) {
        address implementation = extensionOf(msg.sig);
        return Address.functionDelegateCall(implementation, msg.data); // library checks for target contract existence
    }

    receive() external payable virtual {}

    /*===========
        VIEWS
    ===========*/

    /// @dev Function to implement ERC-165 compliance 
    /// @param interfaceId The interface identifier to check.
    /// @return _ Boolean indicating whether the contract supports the specified interface.
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IExtensions).interfaceId;
    }

    /*=============
        SETTERS
    =============*/

    function setExtension(bytes4 selector, address implementation) public virtual canUpdateExtensions {
        _setExtension(selector, implementation);
    }

    function removeExtension(bytes4 selector) public virtual canUpdateExtensions {
        _removeExtension(selector);
    }

    /*===================
        AUTHORIZATION
    ===================*/

    modifier canUpdateExtensions() {
        _checkCanUpdateExtensions();
        _;
    }

    function _checkCanUpdateExtensions() internal virtual;
}
