// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Storage {
    bytes32 internal constant SLOT = keccak256(abi.encode(uint256(keccak256("namespace")) - 1));

    struct Layout {
        bool b;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}
