// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IOwnerInternal} from "./interface/IOwner.sol";
import {OwnerStorage} from "./OwnerStorage.sol";

abstract contract OwnerInternal is IOwnerInternal {
    /*===========
        VIEWS
    ===========*/

    function owner() public view returns (address) {
        return OwnerStorage.layout().owner;
    }

    function pendingOwner() public view virtual returns (address) {
        return OwnerStorage.layout().pendingOwner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != msg.sender) {
            revert OwnerUnauthorizedAccount(msg.sender);
        }
    }

    /*=============
        SETTERS
    =============*/

    function _transferOwnership(address newOwner) internal virtual {
        OwnerStorage.Layout storage layout = OwnerStorage.layout();
        emit OwnershipTransferred(layout.owner, newOwner);
        layout.owner = newOwner;
        delete layout.pendingOwner;
    }

    function _startOwnershipTransfer(address newOwner) internal virtual {
        if (newOwner == address(0)) {
            revert OwnerInvalidOwner(address(0));
        }
        OwnerStorage.Layout storage layout = OwnerStorage.layout();
        layout.pendingOwner = newOwner;
        emit OwnershipTransferStarted(layout.owner, newOwner);
    }

    function _acceptOwnership() internal virtual {
        OwnerStorage.Layout storage layout = OwnerStorage.layout();
        address newOwner = layout.pendingOwner;
        if (newOwner != msg.sender) {
            revert OwnerUnauthorizedAccount(msg.sender);
        }
        _transferOwnership(newOwner);
    }
}
