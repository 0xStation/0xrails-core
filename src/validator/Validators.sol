// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import {IValidators} from "./interface/IValidators.sol";
import {ValidatorsStorage} from "./ValidatorsStorage.sol";

abstract contract Validators is IValidators {

    /// @dev View function to check whether given address has been added as validator
    function isValidator(address validator) public view virtual returns (bool) {
        ValidatorsStorage.Layout storage layout = ValidatorsStorage.layout();
        return layout._validators[validator];
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
        layout._validators[validator] = true;
    }

    function _removeValidator(address validator) internal {
        ValidatorsStorage.Layout storage layout = ValidatorsStorage.layout();
        layout._validators[validator] = false;
    }

    /// @dev Function to be implemented with desired restrictions of access
    /// to adding and removing validator contracts
    function _checkCanUpdateValidators() internal view virtual;
}