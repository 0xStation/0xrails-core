// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library ERC1155Storage {
    bytes32 internal constant SLOT = keccak256(abi.encode(uint256(keccak256("0xrails.ERC1155")) - 1));

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
