// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ITokenMetadataExternal} from "./ITokenMetadata.sol";
import {TokenMetadataInternal} from "./TokenMetadataInternal.sol";
import {TokenMetadataStorage} from "./TokenMetadataStorage.sol";

abstract contract TokenMetadata is TokenMetadataInternal, ITokenMetadataExternal {

    /*=============
        SETTERS
    =============*/

    /// @dev Function to set the name for a token implementation
    /// @param name_ The name string to set
    function setName(string calldata name_) external canUpdateTokenMetadata {
        _setName(name_);
    }

    /// @dev Function to set the symbol for a token implementation
    /// @param symbol_ The symbol string to set
    function setSymbol(string calldata symbol_) external canUpdateTokenMetadata {
        _setSymbol(symbol_);
    }

    /*====================
        AUTHORIZATION
    ====================*/

    modifier canUpdateTokenMetadata() {
        _checkCanUpdateTokenMetadata();
        _;
    }

    /// @dev Function to implement access control restricting setter functions
    function _checkCanUpdateTokenMetadata() internal view virtual;
}
