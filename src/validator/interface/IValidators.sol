// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IValidators {
    error NotEntryPoint(address caller);
    error ValidatorAlreadyExists(address validator);
    error ValidatorDoesNotExist(address validator);

    event ValidatorAdded(address indexed validator);
    event ValidatorRemoved(address indexed validator);

    /// @dev View function to check whether given address has been added as validator
    function isValidator(address validator) external view returns (bool);
    /// @dev View function to retrieve all validators from storage
    function getAllValidators() external view returns (address[] memory validators);
    /// @dev Function to add the address of a Validator module to storage
    function addValidator(address validator) external;
    /// @dev Function to remove the address of a Validator module from storage
    function removeValidator(address validator) external;
}
