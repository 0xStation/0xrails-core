// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IValidators} from "./interface/IValidators.sol";
import {ValidatorsStorage} from "./ValidatorsStorage.sol";

abstract contract Validators is IValidators {

    /// @dev View function to check whether given address has been added as validator
    function isValidator(address validator) public view virtual returns (bool) {
        ValidatorsStorage.Layout storage layout = ValidatorsStorage.layout();
        return layout._validatorData[validator].exists;
    }

    /// @dev View function to retrieve all validators from storage
    function getAllValidators() public view returns (address[] memory validators) {
        ValidatorsStorage.Layout storage layout = ValidatorsStorage.layout();
        return layout._validators;
    }

    /// @dev Function to add the address of a Validator module to storage
    function addValidator(address validator) external {
        _checkCanUpdateValidators();
        _addValidator(validator);
    }

    /// @dev Function to remove the address of a Validator module from storage
    function removeValidator(address validator) external {
        _checkCanUpdateValidators();
        _removeValidator(validator);
    }

    /*===============
        INTERNALS
    ===============*/

    function _addValidator(address validator) internal {
        ValidatorsStorage.Layout storage layout = ValidatorsStorage.layout();

        // check to prevent adding duplicate addresses to `_validators` array
        if (layout._validatorData[validator].exists) {
            revert ValidatorAlreadyExists(validator);
        }

        ValidatorsStorage.ValidatorData memory data = ValidatorsStorage.ValidatorData(
            uint24(layout._validators.length),
            true // ValidatorData.exists
        );
        layout._validatorData[validator] = data;
        layout._validators.push(validator);

        emit ValidatorAdded(validator);
    }

    function _removeValidator(address validator) internal {
        ValidatorsStorage.Layout storage layout = ValidatorsStorage.layout();

        ValidatorsStorage.ValidatorData memory oldValidatorData = layout._validatorData[validator];
        // check to prevent removing 0th index address in `_validators` array
        if (!oldValidatorData.exists) {
            revert ValidatorDoesNotExist(validator);
        }
        
        uint256 lastIndex = layout._validators.length - 1;
        // if removing validator not at the end of the array, swap it to last in array
        if (oldValidatorData.index < lastIndex) {
            address lastValidator = layout._validators[lastIndex];
            // in case new struct members are added, write with entire struct despite redundant `exists`
            layout._validatorData[lastValidator] = oldValidatorData;
            layout._validators[oldValidatorData.index] = lastValidator;
        }

        delete layout._validatorData[validator];
        layout._validators.pop(); // delete validator in last index and decrement length

        emit ValidatorRemoved(validator);
    }

    /// @dev Function to be implemented with desired access control
    function _checkCanUpdateValidators() internal view virtual;
}