// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

library GuardsStorage {
    bytes32 internal constant SLOT = keccak256(abi.encode(uint256(keccak256("0xrails.Guards")) - 1));
    address internal constant MAX_ADDRESS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

    struct Layout {
        bytes8[] _operations;
        mapping(bytes8 => GuardData) _guards;
    }

    struct GuardData {
        uint24 index; //           [0..23]
        uint40 updatedAt; //       [24..63]
        address implementation; // [64..223]
    }
    // thought: add parameters `bool useBefore` and `bool useAfter` to configure if a guard should use both checks or just one

    enum CheckType {
        BEFORE,
        AFTER
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }

    function autoReject(address guard) internal pure returns (bool) {
        return guard == MAX_ADDRESS;
    }

    function autoApprove(address guard) internal pure returns (bool) {
        return guard == address(0);
    }
}
