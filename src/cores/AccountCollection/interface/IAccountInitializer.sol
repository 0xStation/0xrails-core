// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IAccountInitializer {
    // emitted by account
    // reduce event data by fetching account's collection address and token details within indexers
    event AccountInitialized(address indexed accountImpl);

    // @todo: make payable?
    function initializeAccount(address accountImpl, bytes memory initData) external;
}
