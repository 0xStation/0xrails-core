// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IGuards} from "./interface/IGuards.sol";
import {IGuard} from "./interface/IGuard.sol";
import {GuardsStorage} from "./GuardsStorage.sol";
import {Contract} from "../lib/Contract.sol";

abstract contract GuardsInternal is IGuards {
    using GuardsStorage for address;
    /*===========
        HOOKS
    ===========*/

    function checkGuardBefore(bytes8 operation, bytes memory data) public view returns (address guard, bytes memory checkBeforeData) {
        guard = guardOf(operation); 
        if (guard.autoReject()) {
            revert GuardRejected(operation, guard);
        } else if (guard.autoApprove()) {
            return (guard, "");
        }

        checkBeforeData = IGuard(guard).checkBefore(msg.sender, data); // revert will cascade

        return (guard, checkBeforeData);
    }

    function checkGuardAfter(address guard, bytes memory checkBeforeData, bytes memory executionData) public view {
        // only check guard if not autoApprove, autoReject will have already reverted
        if (!guard.autoApprove()) {
            IGuard(guard).checkAfter(checkBeforeData, executionData); // revert will cascade
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

    function _setGuard(bytes8 operation, address implementation) internal {
        GuardsStorage.Layout storage layout = GuardsStorage.layout();
        // require implementation is contract unless it is MAX_ADDRESS
        if (implementation != GuardsStorage.MAX_ADDRESS) {
            Contract._requireContract(implementation); // fails on adding address(0) here
        }

        GuardsStorage.GuardData memory oldGuard = layout._guards[operation];
        if (oldGuard.implementation != address(0)) {
            // update

            if (implementation == oldGuard.implementation) {
                revert GuardUnchanged(operation, oldGuard.implementation, implementation);
            }
            GuardsStorage.GuardData memory newGuard =
                GuardsStorage.GuardData(uint24(oldGuard.index), uint40(block.timestamp), implementation);
            layout._guards[operation] = newGuard;
        } else {
            // add

            // new length will be `len + 1`, so this guard has index `len`
            GuardsStorage.GuardData memory guard =
                GuardsStorage.GuardData(uint24(layout._operations.length), uint40(block.timestamp), implementation);
            layout._guards[operation] = guard;
            layout._operations.push(operation); // set new operation at index and increment length
        }

        emit GuardUpdated(operation, oldGuard.implementation, implementation);
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
}
