// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IInitializerInternal} from "./IInitializer.sol";
import {InitializerStorage} from "./InitializerStorage.sol";

abstract contract Initializer is IInitializerInternal {
    /*===============
        MODIFIERS
    ===============*/

    modifier initializer() {
        InitializerStorage.Layout storage layout = InitializerStorage.layout();
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
        InitializerStorage.Layout storage layout = InitializerStorage.layout();
        if (!layout._initializing) {
            revert NotInitializing();
        }

        _;
    }

    /*===========
        VIEWS
    ===========*/

    function initialized() public view returns (bool) {
        InitializerStorage.Layout storage layout = InitializerStorage.layout();
        return layout._initialized;
    }
}
