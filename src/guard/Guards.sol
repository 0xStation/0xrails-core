// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IGuardsExternal, IGuards} from "./interface/IGuards.sol";
import {GuardsInternal} from "./GuardsInternal.sol";

abstract contract Guards is GuardsInternal, IGuardsExternal {
    /*===========
        VIEWS
    ===========*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IGuards).interfaceId;
    }

    /*=============
        SETTERS
    =============*/

    modifier canUpdateGuards() {
        _checkCanUpdateGuards();
        _;
    }

    function addGuard(bytes8 operation, address implementation) public virtual canUpdateGuards {
        _addGuard(operation, implementation);
    }

    function removeGuard(bytes8 operation) public virtual canUpdateGuards {
        _removeGuard(operation);
    }

    function updateGuard(bytes8 operation, address implementation) public virtual canUpdateGuards {
        _updateGuard(operation, implementation);
    }

    /*===================
        AUTHORIZATION
    ===================*/

    function _checkCanUpdateGuards() internal virtual {}
}
