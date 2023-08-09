// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IGuardsInternal} from "./interface/IGuards.sol";
import {IGuard} from "./interface/IGuard.sol";
import {GuardsStorage} from "./GuardsStorage.sol";
import {Contract} from "../lib/Contract.sol";

abstract contract GuardsInternal is IGuardsInternal {
    using GuardsStorage for address;
    /*===========
        HOOKS
    ===========*/

    modifier checkGuardBeforeAndAfter(bytes8 operation, bytes calldata data) {
        _checkGuard(operation, data, GuardsStorage.CheckType.BEFORE);
        _;
        _checkGuard(operation, data, GuardsStorage.CheckType.AFTER);
    }

    function checkGuardBefore(bytes8 operation, bytes memory data) public view returns (address guard) {
        return _checkGuard(operation, data, GuardsStorage.CheckType.BEFORE);
    }

    function checkGuardAfter(bytes8 operation, bytes memory data) public view returns (address guard) {
        return _checkGuard(operation, data, GuardsStorage.CheckType.AFTER);
    }

    function _checkGuard(bytes8 operation, bytes memory data, GuardsStorage.CheckType check)
        internal
        view
        returns (address guard)
    {
        guard = guardOf(operation);
        if (guard.autoReject()) {
            revert GuardRejected(operation, guard);
        } else if (guard.autoApprove()) {
            return guard;
        }

        bool guardApproves;
        if (check == GuardsStorage.CheckType.BEFORE) {
            guardApproves = IGuard(guard).checkBefore(msg.sender, data);
        } else {
            guardApproves = IGuard(guard).checkAfter(msg.sender, data);
        }

        if (!guardApproves) {
            revert GuardRejected(operation, guard);
        } else {
            return guard;
        }
    }

    /*===========
        VIEWS
    ===========*/

    function guardOf(bytes8 operation) public view returns (address implementation) {
        GuardsStorage.Layout storage layout = GuardsStorage.layout();
        return layout._guards[operation].implementation;
    }

    function getAllGuards() public view virtual returns (Guard[] memory guards) {
        GuardsStorage.Layout storage layout = GuardsStorage.layout();
        uint256 len = layout._operations.length;
        guards = new Guard[](len);
        for (uint256 i; i < len; i++) {
            bytes8 operation = layout._operations[i];
            GuardsStorage.GuardData memory guard = layout._guards[operation];
            guards[i] = Guard(operation, guard.implementation, guard.updatedAt);
        }
        return guards;
    }

    /*=============
        SETTERS
    =============*/

    function _addGuard(bytes8 operation, address implementation) internal {
        GuardsStorage.Layout storage layout = GuardsStorage.layout();
        // require implementation is contract unless it is MAX_ADDRESS
        if (implementation != GuardsStorage.MAX_ADDRESS) {
            Contract._requireContract(implementation); // fails on adding address(0) here
        }
        GuardsStorage.GuardData memory oldGuard = layout._guards[operation];
        if (oldGuard.implementation != address(0)) revert GuardAlreadyExists(operation, oldGuard.implementation);

        GuardsStorage.GuardData memory guard =
            GuardsStorage.GuardData(uint24(layout._operations.length), uint40(block.timestamp), implementation); // new length will be `len + 1`, so this guard has index `len`

        layout._guards[operation] = guard;
        layout._operations.push(operation); // set new operation at index and increment length

        emit GuardUpdated(operation, address(0), implementation);
    }

    function _removeGuard(bytes8 operation) internal {
        GuardsStorage.Layout storage layout = GuardsStorage.layout();
        GuardsStorage.GuardData memory oldGuard = layout._guards[operation];
        if (oldGuard.implementation == address(0)) revert GuardDoesNotExist(operation);

        uint256 lastIndex = layout._operations.length - 1;
        // if removing extension not at the end of the array, swap extension with last in array
        if (oldGuard.index < lastIndex) {
            bytes8 lastOperation = layout._operations[lastIndex];
            GuardsStorage.GuardData memory lastGuard = layout._guards[lastOperation];
            lastGuard.index = oldGuard.index;
            layout._operations[oldGuard.index] = lastOperation;
            layout._guards[lastOperation] = lastGuard;
        }
        delete layout._guards[operation];
        layout._operations.pop(); // delete guard in last index and decrement length

        emit GuardUpdated(operation, oldGuard.implementation, address(0));
    }

    function _updateGuard(bytes8 operation, address implementation) internal {
        GuardsStorage.Layout storage layout = GuardsStorage.layout();
        Contract._requireContract(implementation);
        GuardsStorage.GuardData memory oldGuard = layout._guards[operation];
        if (oldGuard.implementation == address(0)) revert GuardDoesNotExist(operation);
        if (implementation == oldGuard.implementation) {
            revert GuardUnchanged(operation, oldGuard.implementation, implementation);
        }

        GuardsStorage.GuardData memory newGuard =
            GuardsStorage.GuardData(uint24(oldGuard.index), uint40(block.timestamp), implementation);
        layout._guards[operation] = newGuard;

        emit GuardUpdated(operation, oldGuard.implementation, implementation);
    }
}
