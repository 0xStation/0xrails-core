// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @notice using the consistent Access layer, expose external functions for interacting with core token logic
interface IERC721Mage {
    error CannotInitializeWhileConstructing();

    function mintTo(address recipient, uint256 quantity) external;
    function burn(uint256 tokenId) external;
    function initialize(address owner, string calldata name, string calldata symbol, bytes calldata initData)
        external;
}
