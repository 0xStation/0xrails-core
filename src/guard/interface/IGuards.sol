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
    error GuardUnchanged(bytes8 operation, address oldImplementation, address newImplementation);
    error GuardRejected(bytes8 operation, address guard);
}

/// @notice Since the Solidity compiler ignores inherited functions, function declarations are made
/// at the top level so their selectors are properly XORed into a nonzero `interfaceId`
interface IGuards is IGuardsInternal {
    // IGuardsInternal views
    function checkGuardBefore(bytes8 operation, bytes calldata data) external view returns (address guard, bytes memory checkBeforeData);
    function checkGuardAfter(address guard, bytes calldata checkBeforeData, bytes calldata executionData) external view;
    function guardOf(bytes8 operation) external view returns (address implementation);
    function getAllGuards() external view returns (Guard[] memory Guards);
    // external setters
    function setGuard(bytes8 operation, address implementation) external;
    function removeGuard(bytes8 operation) external;
}
