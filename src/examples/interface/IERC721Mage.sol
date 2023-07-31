// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @notice using the consistent Access layer, expose external functions for interacting with core token logic
interface IERC721Mage {
    function batchMintTo(address recipient, uint256 quantity) external;
    function mintTo(address recipient) external;
    function burn(uint256 tokenId) external;
}
