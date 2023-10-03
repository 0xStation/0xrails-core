// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC6551AccountInitializer {
    // @todo: make payable?
    function initializeAccount(address accountImpl, bytes memory initData) external;
}
