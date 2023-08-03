// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IGuardsInternal {
    struct Guard {
        bytes8 operation;
        address implementation;
        uint40 updatedAt;
    }

    // events
    event GuardUpdated(bytes8 indexed operation, address indexed oldGuard, address indexed newGuard);

    // errors
    error GuardDoesNotExist(bytes8 operation);
    error GuardAlreadyExists(bytes8 operation, address guard);
    error GuardUnchanged(bytes8 operation, address oldImplementation, address newImplementation);
    error GuardRejected(bytes8 operation, address operator, address guard, bytes data);

    // hooks
    function checkGuardBefore(bytes8 operation, bytes calldata data) external view returns (address guard);
    function checkGuardAfter(bytes8 operation, bytes calldata data) external view returns (address guard);
    // views
    function guardOf(bytes8 operation) external view returns (address implementation);
    function getAllGuards() external view returns (Guard[] memory Guards);
}

interface IGuardsExternal {
    // setters
    function addGuard(bytes8 operation, address implementation) external;
    function removeGuard(bytes8 operation) external;
    function updateGuard(bytes8 operation, address implementation) external;
}

interface IGuards is IGuardsInternal, IGuardsExternal {}
