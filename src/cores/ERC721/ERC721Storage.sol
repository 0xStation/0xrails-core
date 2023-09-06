// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library ERC721Storage {
    bytes32 internal constant SLOT = keccak256(abi.encode(uint256(keccak256("0xrails.ERC721")) - 1));

    struct Layout {
        uint256 currentIndex; // max supply is 18e18
        uint256 burnCounter;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
        mapping(uint256 => TokenData) tokens;
        mapping(address => OwnerData) owners;
    }

    struct TokenData {
        // ERC-721
        address owner; //         [0..159]
        // ERC-721A
        uint48 ownerUpdatedAt; // [160..207]
        bool burned; //           [208..215]
        bool nextInitialized; //  [216..223]
    }

    struct OwnerData {
        // ERC-721
        uint64 balance; //   [0..63]
        // ERC-721A
        uint64 numMinted; // [64..127]
        uint64 numBurned; // [128..191]
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}
