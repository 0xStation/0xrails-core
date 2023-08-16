// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library ERC721Storage {
    bytes32 internal constant SLOT = keccak256(abi.encode(uint256(keccak256("mage.ERC721")) - 1));

    struct Layout {
        uint64 currentIndex; // max supply is 18e18
        uint64 burnCounter;
        mapping(uint256 => TokenData) tokens;
        mapping(address => OwnerData) owners;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    struct TokenData {
        // ERC-721
        address owner;
        // ERC-721A
        bool burned;
        bool nextInitialized;
    }

    struct OwnerData {
        // ERC-721
        uint64 balance;
        // ERC-721A
        uint64 numMinted;
        uint64 numBurned;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}
