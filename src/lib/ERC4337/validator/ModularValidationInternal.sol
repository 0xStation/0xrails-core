// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import {IModularValidation} from "./interface/IModularValidation.sol";
import {ModularValidationStorage} from "./ModularValidationStorage.sol";

abstract contract ModularValidationInternal is IModularValidation {

    /// @dev View function to get the ERC-4337 EntryPoint contract address for this chain
    function isValidator(address validator) public view virtual returns (bool) {
        ModularValidationStorage.Layout storage layout = ModularValidationStorage.layout();
        return layout._validators[validator];
    }

    /// @notice The following functions should be implemented with strict access control
    /// as they can allow signature verification capabilities to potentially malicious contracts 
    function addValidator(address validator) external virtual;
    function removeValidator(address validator) external virtual;
}