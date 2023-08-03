// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Storage {
    bytes32 internal constant SLOT = bytes32(uint256(keccak256("mage.Initializable")) - 1);

    struct Layout {
        bool _initialized;
        bool _initializing;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}
