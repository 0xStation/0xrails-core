// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC6551AccountInitializer {
    function initializeAccount(address accountImpl, bytes memory initData) external payable;
}
