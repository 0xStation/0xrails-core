// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Storage {
    // `keccak256(abi.encode(uint256(keccak256("namespace")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0x46cbbdff1956914b6103e7e1793afa95ddbf9635fe5337f8c9429bcb2ab01b00;

    struct Layout {
        bool b;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}
