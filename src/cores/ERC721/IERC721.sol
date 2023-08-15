// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC721Internal {
    // events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    // errors
    error MintZeroQuantity();
    error MintToZeroAddress();

    // views
    function foo() external;
}

interface IERC721External {
    // setters
    function bar() external;
}

interface IERC721 is IERC721Internal, IERC721External {}
