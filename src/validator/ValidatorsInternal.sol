// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import {IValidators} from "./interface/IValidators.sol";
import {ValidatorsStorage} from "./ValidatorsStorage.sol";

abstract contract ValidatorsInternal is IValidators {

    /// @dev View function to check whether given address has been added as validator
    function isValidator(address validator) public view virtual returns (bool) {
        ValidatorsStorage.Layout storage layout = ValidatorsStorage.layout();
        return layout._validators[validator];
    }

    /// @notice The following functions should be implemented with strict access control
    /// as they can allow signature verification capabilities to potentially malicious contracts 
    function addValidator(address validator) external virtual;
    function removeValidator(address validator) external virtual;
}