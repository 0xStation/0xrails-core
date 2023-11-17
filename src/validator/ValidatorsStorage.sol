// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library ValidatorsStorage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.Validators")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0x501077102342bdb85f23d25bb36efd0f86b07c38e46b63bec983266db4374200;

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
