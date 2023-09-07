// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library InitializableStorage {
    bytes32 internal constant SLOT = keccak256(abi.encode(uint256(keccak256("0xrails.Initializable")) - 1));

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
