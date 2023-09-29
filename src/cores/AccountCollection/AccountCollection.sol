// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {AccountCollectionStorage} from "./AccountCollectionStorage.sol";
import {IAccountCollection} from "./interface/IAccountCollection.sol";

abstract contract AccountCollection is IAccountCollection {
    function getAccountInitializer() public view returns (address) {
        return AccountCollectionStorage.layout().initializerImpl;
    }

    function setAccountInitializer(address impl) public {
        _checkCanUpdateAccountInitializer();
        _setAccountInitializer(impl);
    }

    function _setAccountInitializer(address impl) internal {
        AccountCollectionStorage.Layout storage layout = AccountCollectionStorage.layout();
        emit AccountInitializerUpdated(layout.initializerImpl, impl);
        layout.initializerImpl = impl;
    }

    function _checkCanUpdateAccountInitializer() internal virtual;
}
