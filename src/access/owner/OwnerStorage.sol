// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library OwnerStorage {
    bytes32 internal constant SLOT = bytes32(uint256(keccak256("mage.Owner")) - 1);

    struct Layout {
        address owner;
        address pendingOwner;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}
