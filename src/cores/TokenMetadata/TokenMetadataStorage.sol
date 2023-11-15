// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library TokenMetadataStorage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.TokenMetadata")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0x4f2e116bc9c7d925ed26e4ecc4178db33477c50c415adbd68f1ed8f0d8dace00;

    struct Layout {
        string name;
        string symbol;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}
