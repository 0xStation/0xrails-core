// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {OwnerInternal} from "./OwnerInternal.sol";
import {IOwnerExternal} from "./interface/IOwner.sol";

abstract contract Owner is OwnerInternal, IOwnerExternal {
    /*=============
        SETTERS
    =============*/

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        _startOwnershipTransfer(newOwner);
    }

    function acceptOwnership() public virtual {
        _acceptOwnership();
    }
}
