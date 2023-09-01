// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// set up receivers to accept token transfers
contract MockAccount {
    receive() external payable virtual {}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

contract MockAccountDeployer {
    function createAccount() public returns (address account) {
        return address(new MockAccount());
    }
}