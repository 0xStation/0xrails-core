// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {OwnableInternal} from "./OwnableInternal.sol";
import {IOwnableExternal} from "./interface/IOwnable.sol";

abstract contract Ownable is OwnableInternal, IOwnableExternal {
    /*=============
        SETTERS
    =============*/

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
