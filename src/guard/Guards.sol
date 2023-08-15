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

    /// @notice Due to EXTCODESIZE check within `_requireContract()`, this function will revert if called
    /// during the constructor of the contract at `implementation`. Deploy `implementation` contract first.
    function setGuard(bytes8 operation, address implementation) public virtual canUpdateGuards {
        _setGuard(operation, implementation);
    }

    function removeGuard(bytes8 operation) public virtual canUpdateGuards {
        _removeGuard(operation);
    }

    /*===================
        AUTHORIZATION
    ===================*/

    modifier canUpdateGuards() {
        _checkCanUpdateGuards();
        _;
    }

    function _checkCanUpdateGuards() internal virtual;
}
