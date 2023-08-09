// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library SupportsInterfaceStorage {
    bytes32 internal constant SLOT = keccak256(abi.encode(uint256(keccak256("mage.SupportsInterface")) - 1));

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
