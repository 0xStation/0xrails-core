// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library ValidatorsStorage {
    bytes32 internal constant SLOT = keccak256(abi.encode(uint256(keccak256("0xrails.Validators")) - 1));

    struct Layout {
        address[] _validators;
        mapping(address => ValidatorData) _validatorData;
    }

    struct ValidatorData {
        uint24 index;
        bool exists;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}