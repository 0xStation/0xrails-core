// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC1967Upgrade} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Upgrade.sol";

import {IERC6551AccountInitializer} from "../interface/IERC6551AccountInitializer.sol";
import {ERC6551AccountGroupLib} from "src/lib/ERC6551/ERC6551AccountGroupLib.sol";
import {IGuards} from "src/guard/interface/IGuards.sol";
import {Operations} from "src/lib/Operations.sol";

// A simple Account initializer
contract ERC6551AccountInitializerSimple is IERC6551AccountInitializer, ERC1967Upgrade {
    // delegatecalled by Account 1167Proxy
    function initializeAccount(address accountImpl, bytes memory initData) external {
        // save accountImpl to 1967 slot and initialize account, emits Upgraded(address) event
        ERC1967Upgrade._upgradeToAndCall(accountImpl, initData, false);
    }
}
