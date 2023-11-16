// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IGuards {
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

    /// @dev Perform checks before executing a specific operation and return guard information.
    /// @param operation The operation identifier to check.
    /// @param data Additional data associated with the operation.
    /// @return guard The address of the guard contract responsible for the operation.
    /// @return checkBeforeData Additional data from the guard contract's checkBefore function.
    function checkGuardBefore(bytes8 operation, bytes calldata data)
        external
        view
        returns (address guard, bytes memory checkBeforeData);

    /// @dev Perform checks after executing an operation.
    /// @param guard The address of the guard contract responsible for the operation.
    /// @param checkBeforeData Additional data obtained from the guard's checkBefore function.
    /// @param executionData The execution data associated with the operation.
    function checkGuardAfter(address guard, bytes calldata checkBeforeData, bytes calldata executionData)
        external
        view;

    /// @dev Get the guard contract address responsible for a specific operation.
    /// @param operation The operation identifier.
    /// @return implementation The address of the guard contract for the operation.
    function guardOf(bytes8 operation) external view returns (address implementation);
    
    /// @dev Get an array of all registered guard contracts.
    /// @return Guards An array containing information about all registered guard contracts.
    function getAllGuards() external view returns (Guard[] memory Guards);

    /// @dev Set a guard contract for a specific operation.
    /// @param operation The operation identifier for which to set the guard contract.
    /// @param implementation The address of the guard contract to set.
    function setGuard(bytes8 operation, address implementation) external;

    /// @dev Remove the guard contract for a specific operation.
    /// @param operation The operation identifier for which to remove the guard contract.
    function removeGuard(bytes8 operation) external;
}
