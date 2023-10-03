// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library ERC6551AccountStorage {
    bytes32 internal constant SLOT = keccak256(abi.encode(uint256(keccak256("0xrails.ERC6551Account")) - 1));

    struct Layout {
        uint256 state;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}
