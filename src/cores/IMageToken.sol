// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IMageToken {
    function initialize(address owner, string calldata name, string calldata symbol, bytes[] calldata initCalls)
        external;
}
