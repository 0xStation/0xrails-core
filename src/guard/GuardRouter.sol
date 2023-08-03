// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IGuardRouter} from "./interface/IGuardRouter.sol";
import {IGuard} from "./interface/IGuard.sol";
import {Contract} from "src/lib/Contract.sol";

abstract contract GuardRouter is IGuardRouter {
    // default value for a guard that always rejects
    address constant MAX_ADDRESS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

    bytes8[] internal _operations;
    mapping(bytes8 => GuardData) internal _guards;

    /*===========
        VIEWS
    ===========*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IGuardRouter).interfaceId;
    }

    function guardOf(bytes8 operation) public view returns (address implementation) {
        return _guards[operation].implementation;
    }

    function getAllGuards() public view virtual returns (Guard[] memory guards) {
        uint256 len = _operations.length;
        guards = new Guard[](len);
        for (uint256 i; i < len; i++) {
            bytes8 operation = _operations[i];
            GuardData memory guard = _guards[operation];
            guards[i] = Guard(operation, guard.implementation, guard.updatedAt);
        }
        return guards;
    }

    /*===========
        HOOKS
    ===========*/

    modifier checkGuardBeforeAndAfter(bytes8 operation, bytes calldata data) {
        checkGuardBefore(operation, data);
        _;
        checkGuardAfter(operation, data);
    }

    function checkGuardBefore(bytes8 operation, bytes memory data) public view returns (address guard) {
        guard = guardOf(operation);
        if (guard == MAX_ADDRESS || (guard != address(0) && !IGuard(guard).checkBefore(msg.sender, data))) {
            revert GuardRejected(operation, msg.sender, guard, data);
        }
    }

    function checkGuardAfter(bytes8 operation, bytes memory data) public view returns (address guard) {
        guard = guardOf(operation);
        if (guard == MAX_ADDRESS || (guard != address(0) && !IGuard(guard).checkAfter(msg.sender, data))) {
            revert GuardRejected(operation, msg.sender, guard, data);
        }
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

    /*===============
        INTERNALS
    ===============*/

    function _addGuard(bytes8 operation, address implementation) internal {
        Contract._requireContract(implementation);
        GuardData memory oldGuard = _guards[operation];
        if (oldGuard.implementation != address(0)) revert GuardAlreadyExists(operation, oldGuard.implementation);

        GuardData memory guard = GuardData(uint24(_operations.length), uint40(block.timestamp), implementation); // new length will be `len + 1`, so this guard has index `len`

        _guards[operation] = guard;
        _operations.push(operation); // set new operation at index and increment length

        emit GuardUpdated(operation, address(0), implementation);
    }

    function _removeGuard(bytes8 operation) internal {
        GuardData memory oldGuard = _guards[operation];
        if (oldGuard.implementation == address(0)) revert GuardDoesNotExist(operation);

        uint256 lastIndex = _operations.length - 1;
        // if removing extension not at the end of the array, swap extension with last in array
        if (oldGuard.index < lastIndex) {
            bytes8 lastOperation = _operations[lastIndex];
            GuardData memory lastGuard = _guards[lastOperation];
            lastGuard.index = oldGuard.index;
            _operations[oldGuard.index] = lastOperation;
            _guards[lastOperation] = lastGuard;
        }
        delete _guards[operation];
        _operations.pop(); // delete guard in last index and decrement length

        emit GuardUpdated(operation, oldGuard.implementation, address(0));
    }

    function _updateGuard(bytes8 operation, address implementation) internal {
        Contract._requireContract(implementation);
        GuardData memory oldGuard = _guards[operation];
        if (oldGuard.implementation == address(0)) revert GuardDoesNotExist(operation);
        if (implementation == oldGuard.implementation) {
            revert GuardUnchanged(operation, oldGuard.implementation, implementation);
        }

        GuardData memory newGuard = GuardData(uint24(oldGuard.index), uint40(block.timestamp), implementation);
        _guards[operation] = newGuard;

        emit GuardUpdated(operation, oldGuard.implementation, implementation);
    }

    /*===================
        AUTHORIZATION
    ===================*/

    function _checkCanUpdateGuards() internal virtual {}
}
