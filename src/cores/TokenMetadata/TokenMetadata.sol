// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ITokenMetadataExternal} from "./ITokenMetadata.sol";
import {TokenMetadataInternal} from "./TokenMetadataInternal.sol";
import {TokenMetadataStorage} from "./TokenMetadataStorage.sol";

abstract contract TokenMetadata is TokenMetadataInternal, ITokenMetadataExternal {
    /*===========
        VIEWS
    ===========*/

    /*=============
        SETTERS
    =============*/
    
    function setName(string calldata name_) external canUpdateTokenMetadata {
        _setName(name_);
    }
    
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

    function _checkCanUpdateTokenMetadata() internal view virtual;
}
