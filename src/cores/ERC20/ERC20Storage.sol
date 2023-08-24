// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library ERC20Storage {
    bytes32 internal constant SLOT = keccak256(abi.encode(uint256(keccak256("mage.ERC20")) - 1));

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
