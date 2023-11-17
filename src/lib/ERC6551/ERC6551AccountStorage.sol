// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library ERC6551AccountStorage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.ERC6551Account")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0xa0f58fa5523f3cd0666c678d77377af6b951392a937ada077eff4c3675457d00;

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
