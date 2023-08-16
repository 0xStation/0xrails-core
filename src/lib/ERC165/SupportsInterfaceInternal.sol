// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ISupportsInterfaceInternal} from "./ISupportsInterface.sol";
import {SupportsInterfaceStorage} from "./SupportsInterfaceStorage.sol";

abstract contract SupportsInterfaceInternal is ISupportsInterfaceInternal {
    /*===========
        VIEWS
    ===========*/
    function _supportsInterface(bytes4 interfaceId) internal view returns (bool) {
        SupportsInterfaceStorage.Layout storage layout = SupportsInterfaceStorage.layout();
        return layout._supportsInterface[interfaceId];
    }

    /*=============
        SETTERS
    =============*/

    function _addInterface(bytes4 interfaceId) internal {
        SupportsInterfaceStorage.Layout storage layout = SupportsInterfaceStorage.layout();
        if (layout._supportsInterface[interfaceId]) revert InterfaceAlreadyAdded(interfaceId);
        layout._supportsInterface[interfaceId] = true;
    }

    function _removeInterface(bytes4 interfaceId) internal {
        SupportsInterfaceStorage.Layout storage layout = SupportsInterfaceStorage.layout();
        if (!layout._supportsInterface[interfaceId]) revert InterfaceNotAdded(interfaceId);
        delete layout._supportsInterface[interfaceId];
    }

    /*====================
        AUTHORIZATION
    ====================*/
}
