// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {AccountCollectionLib} from "./AccountCollectionLib.sol";
import {IAccountInitializer} from "./interface/IAccountInitializer.sol";
import {IAccountCollection} from "./interface/IAccountCollection.sol";

contract AccountCollectionProxy is ERC1967Proxy, IAccountInitializer {
    address immutable self;

    constructor(address accountCollectionImpl, bytes memory initData) ERC1967Proxy(accountCollectionImpl, initData) {
        self = address(this);
    }

    function initializeAccount(address, bytes memory) external {
        // address initializer = IAccountCollection(AccountCollectionLib.accountCollection()).getAccountInitializer();
        address initializer = IAccountCollection(self).getAccountInitializer();
        _delegate(initializer);
    }
}
