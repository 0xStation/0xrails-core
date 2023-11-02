// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC6551AccountGroup {
    function getAccountInitializer(address account) external view returns (address initializer);
    /// @dev Function to return a subgroupId's approved account implementation upgrade options
    function getApprovedImplementations(address account) external view returns (address[] memory);
    /// @dev Function to add a new approved account implementation to storage
    function addApprovedImplementation(uint64 subgroupId, address implementation) external;
    /// @dev Function to delete a previously approved account implementation from storage
    function removeApprovedImplementation(uint64 subgroupId, address implementation) external;
}
