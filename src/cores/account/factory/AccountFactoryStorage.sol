// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @title Station Network AccountFactory Namespace Storage Contract
/// @author 👦🏻👦🏻.eth

/// @dev This library uses ERC7201 namespace storage
/// to provide a collision-resistant ledger of current account implementations
library AccountFactoryStorage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.AccountFactory")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0x9cefdb8cee5533676925ff2338aa35f7efbe2e62f58973799008a6274c385700;

    struct Layout {
        address accountImpl;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}
