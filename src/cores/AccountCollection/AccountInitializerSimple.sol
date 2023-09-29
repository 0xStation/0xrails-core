// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC1967Upgrade} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Upgrade.sol";
import {IAccountInitializer} from "./interface/IAccountInitializer.sol";
import {AccountCollectionLib} from "./AccountCollectionLib.sol";
import {IGuards} from "../../guard/interface/IGuards.sol";
import {Operations} from "../../lib/Operations.sol";
// import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";

// Account initializer designed for use with AccountCollectionRails
contract AccountInitializerSimple is IAccountInitializer, ERC1967Upgrade {
    // delegatecalled by Account 1167Proxy
    function initializeAccount(address accountImpl, bytes memory initData) external {
        // save accountImpl to 1967 slot and initialize account
        ERC1967Upgrade._upgradeToAndCall(accountImpl, initData, false);
        emit AccountInitialized(accountImpl);
    }
}
