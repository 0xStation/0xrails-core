// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {IERC6551AccountInitializer} from "../interface/IERC6551AccountInitializer.sol";
import {IERC6551AccountGroup} from "../interface/IERC6551AccountGroup.sol";
import {ERC6551AccountGroupLib} from "src/lib/ERC6551/ERC6551AccountGroupLib.sol";

contract ERC6551AccountGroupProxy is ERC1967Proxy, IERC6551AccountInitializer {
    constructor(address owner, bytes memory initData) ERC1967Proxy(owner, initData) {}

    function initializeAccount(address, bytes memory) external {
        address initializer = IERC6551AccountGroup(ERC6551AccountGroupLib.accountGroup()).getAccountInitializer();
        _delegate(initializer);
    }
}
