// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC1967Upgrade} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Upgrade.sol";

import {IERC6551AccountInitializer} from "./interface/IERC6551AccountInitializer.sol";

// Only initialize accounts with an implementation
abstract contract AccountInitializer is IERC6551AccountInitializer, ERC1967Upgrade {
    error AlreadyInitialized();

    /// @notice delegatecall'ed by ERC6551 Account 1167Proxy
    function initializeAccount(address accountImpl, bytes memory initData) external payable {
        // enforce initialization on un-initialized contracts, functions as signature replay protection
        if (ERC1967Upgrade._getImplementation() != address(0)) revert AlreadyInitialized();
        // authenticate initialization
        bytes memory accountData = _authenticateInitialization(accountImpl, initData);
        // save accountImpl to 1967 slot and initialize account data, emits Upgraded(address) event
        ERC1967Upgrade._upgradeToAndCall(accountImpl, accountData, false);
    }

    /// @notice Check is account implementation is allowed, strip provided initData
    function _authenticateInitialization(address accountImpl, bytes memory initData)
        internal
        view
        virtual
        returns (bytes memory accountData); // actual data to initialize account with
}
