// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC1155Mage {
    function mintTo(address recipient, uint256 tokenId, uint256 value) external;
    function burnFrom(address from, uint256 tokenId, uint256 value) external;
    function initialize(address owner, string calldata name, string calldata symbol, bytes calldata initData)
        external;
}
