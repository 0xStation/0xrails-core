// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IGuardRouter {
    struct GuardData {
        uint24 index; //           [0..23]
        uint40 updatedAt; //       [24..63]
        address implementation; // [64..223]
    }

    struct Guard {
        bytes8 operation;
        address implementation;
        uint40 updatedAt;
    }

    event GuardUpdated(bytes8 indexed operation, address indexed oldGuard, address indexed newGuard);

    error GuardDoesNotExist(bytes8 operation);
    error GuardAlreadyExists(bytes8 operation, address guard);
    error GuardUnchanged(bytes8 operation, address oldImplementation, address newImplementation);
    error GuardRejected(bytes8 operation, address operator, address guard, bytes data);

    // views
    function guardOf(bytes8 operation) external view returns (address implementation);
    function getAllGuards() external view returns (Guard[] memory guards);
    // hooks
    function checkGuardBefore(bytes8 operation, bytes calldata data) external view returns (address guard);
    function checkGuardAfter(bytes8 operation, bytes calldata data) external view returns (address guard);
    // setters
    function addGuard(bytes8 operation, address implementation) external;
    function removeGuard(bytes8 operation) external;
    function updateGuard(bytes8 operation, address implementation) external;
}
