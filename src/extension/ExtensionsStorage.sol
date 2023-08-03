// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

library ExtensionsStorage {
    bytes32 internal constant SLOT = bytes32(uint256(keccak256("mage.Extensions")) - 1);

    struct Layout {
        bytes4[] _selectors;
        mapping(bytes4 => ExtensionData) _extensions;
    }

    struct ExtensionData {
        uint24 index; //           [0..23]
        uint40 updatedAt; //       [24..63]
        address implementation; // [64..223]
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}
