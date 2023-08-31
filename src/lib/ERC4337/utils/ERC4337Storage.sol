// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library ERC4337Storage {
    bytes32 internal constant SLOT = keccak256(abi.encode(uint256(keccak256("mage.ERC4337")) - 1));


    struct Layout {
        /// @dev This chain's EntryPoint contract address
        address entryPoint;
        /// @dev In case of 4337 `validateUserOp()` failure, return value need not include time range
        uint8 SIG_VALIDATION_FAILED;
        /// @dev In case of 1271 `isValidSignature()` failure, use this error code (`0xffffffff`)
        bytes4 INVALID_SIGNER;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}