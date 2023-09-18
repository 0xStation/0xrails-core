// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IValidators {
    error NotEntryPoint(address caller);
    error ValidatorAlreadyExists(address validator);
    error ValidatorDoesNotExist(address validator);

    event ValidatorAdded(address indexed validator);
    event ValidatorRemoved(address indexed validator);

    function isValidator(address validator) external view returns (bool);
    function getAllValidators() external view returns (address[] memory validators);
    function addValidator(address validator) external;
    function removeValidator(address validator) external;
}
