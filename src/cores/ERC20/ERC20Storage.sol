// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library ERC20Storage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.ERC20")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0xcc1a765547cda1929f5295f82a3b2c17f80d5562fb7a939737a5cdd530117500;

    struct Layout {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 totalSupply;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}
