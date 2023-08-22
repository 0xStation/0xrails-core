// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IInitializableInternal} from "./IInitializable.sol";
import {InitializableStorage} from "./InitializableStorage.sol";

abstract contract Initializable is IInitializableInternal {

    /*===========
        LOCK
    ===========*/
    
    /// @dev Logic implementation contract disables `initialize()` from being called 
    /// to prevent privilege escalation and 'exploding kitten' attacks  
    constructor() {
        _disableInitializers();
    }

    function _disableInitializers() internal virtual {
        InitializableStorage.Layout storage layout = InitializableStorage.layout();

        if (layout._initializing) {
            revert AlreadyInitialized();
        }
        if (layout._initialized == false) {
            layout._initialized = true;
            emit Initialized();
        }
    }
    
    /*===============
        MODIFIERS
    ===============*/

    modifier initializer() {
        InitializableStorage.Layout storage layout = InitializableStorage.layout();
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
        InitializableStorage.Layout storage layout = InitializableStorage.layout();
        if (!layout._initializing) {
            revert NotInitializing();
        }

        _;
    }

    /*===========
        VIEWS
    ===========*/

    function initialized() public view returns (bool) {
        InitializableStorage.Layout storage layout = InitializableStorage.layout();
        return layout._initialized;
    }
}
