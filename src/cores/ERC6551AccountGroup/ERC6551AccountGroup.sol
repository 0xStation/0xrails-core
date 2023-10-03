// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC6551AccountGroupStorage} from "./ERC6551AccountGroupStorage.sol";
import {IERC6551AccountGroup} from "./interface/IERC6551AccountGroup.sol";

abstract contract ERC6551AccountGroup is IERC6551AccountGroup {
    function getAccountInitializer() public view returns (address) {
        return ERC6551AccountGroupStorage.layout().initializerImpl;
    }

    function setAccountInitializer(address impl) public {
        _checkCanUpdateERC6551AccountInitializer();
        _setAccountInitializer(impl);
    }

    function _setAccountInitializer(address impl) internal {
        ERC6551AccountGroupStorage.Layout storage layout = ERC6551AccountGroupStorage.layout();
        emit ERC6551AccountInitializerUpdated(layout.initializerImpl, impl);
        layout.initializerImpl = impl;
    }

    function _checkCanUpdateERC6551AccountInitializer() internal virtual;
}
