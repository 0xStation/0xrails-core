// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library ValidatorsStorage {
    bytes32 internal constant SLOT = keccak256(abi.encode(uint256(keccak256("mage.ModularValidation")) - 1));

    struct Layout {
        mapping(address => bool) _validators;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}