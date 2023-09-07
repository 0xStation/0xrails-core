// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @title Station Network AccountFactory Namespace Storage Contract
/// @author 👦🏻👦🏻.eth

/// @dev This library uses ERC7201 namespace storage
/// to provide a collision-resistant ledger of current account implementations
library AccountFactoryStorage {
    bytes32 internal constant SLOT = keccak256(abi.encode(uint256(keccak256("0xrails.AccountFactory")) - 1));

    struct Layout {
        address[] accountImpls;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}