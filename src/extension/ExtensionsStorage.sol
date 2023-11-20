// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

library ExtensionsStorage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.Extensions")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0x24b223a3be882d5d1d257152fdb15a02ae59c6d11e58bc0c17888d15a9b15b00;

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
