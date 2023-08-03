// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {InterfaceInternal} from "./Interface.sol";
import {Storage} from "./Storage.sol";

abstract contract Internal is InterfaceInternal {
    /*===============
        MODIFIERS
    ===============*/

    modifier initializer() {
        Storage.Layout storage layout = Storage.layout();
        if (layout._initialized) {
            revert AlreadyInitialized();
        }
        layout._initializing = true;

        _;

        layout._initializing = false;
        layout._initialized = true;
        emit Initialized();
    }

    modifier onlyInitializing() {
        Storage.Layout storage layout = Storage.layout();
        if (!layout._initializing) {
            revert NotInitializing();
        }

        _;
    }

    /*===========
        VIEWS
    ===========*/

    function initialized() public view returns (bool) {
        Storage.Layout storage layout = Storage.layout();
        return layout._initialized;
    }
}
