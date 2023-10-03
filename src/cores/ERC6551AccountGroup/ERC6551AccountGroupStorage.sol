// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library ERC6551AccountGroupStorage {
    bytes32 internal constant SLOT = keccak256(abi.encode(uint256(keccak256("0xrails.ERC6551AccountGroup")) - 1));

    struct Layout {
        address initializerImpl;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}
