// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library SupportsInterfaceStorage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.SupportsInterface")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0x95a5ecff3e5709ffcdce1ca934c4b897d39c8a95719755d12b7d1e124ce29700;

    struct Layout {
        mapping(bytes4 => bool) _supportsInterface;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}
