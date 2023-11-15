// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

library GuardsStorage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.Guards")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0x68fdbc9be968974abe602a5cbdd43c5fd2f2d66bfde2f0188149c63e523d4d00;
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

    /// @dev Function to check for guards that have been set to the max address,
    /// signaling automatic rejection of an operation
    function autoReject(address guard) internal pure returns (bool) {
        return guard == MAX_ADDRESS;
    }

    /// @dev Function to check for guards that have been set to the zero address,
    /// signaling automatic approval of an operation
    function autoApprove(address guard) internal pure returns (bool) {
        return guard == address(0);
    }
}
