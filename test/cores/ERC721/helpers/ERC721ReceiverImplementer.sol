// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @dev Harness contract implementing `_checkOnERC721Received()` and nothing else
/// to accept `ERC721::safeTransfer()` for testing purposes
contract ERC721ReceiverImplementer {
    function onERC721Received(address, address, uint256, bytes memory) public pure returns (bytes4 retvalue) {
        return this.onERC721Received.selector;
    }
}
