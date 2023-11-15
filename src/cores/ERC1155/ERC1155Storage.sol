// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library ERC1155Storage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.ERC1155")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0x952dbaf1612c9c8046b26f71d8522ed2497f086620534427664d0784cf404500;

    struct Layout {
        // id => account => balance
        mapping(uint256 => mapping(address => uint256)) balances;
        // account => operator => t/f
        mapping(address => mapping(address => bool)) operatorApprovals;
        // id => supply
        mapping(uint256 => uint256) totalSupply;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}
