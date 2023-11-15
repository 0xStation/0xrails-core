// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library InitializableStorage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.Initializable")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0x8ca77559b51bdadaef66f8dec08105b4dd195463fda0f501696f5581b908dc00;

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
