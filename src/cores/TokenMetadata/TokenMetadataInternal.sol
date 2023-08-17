// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ITokenMetadataInternal} from "./ITokenMetadata.sol";
import {TokenMetadataStorage} from "./TokenMetadataStorage.sol";

abstract contract TokenMetadataInternal is ITokenMetadataInternal {
    /*===========
        VIEWS
    ===========*/
    
    function name() public view virtual returns (string memory) {
        TokenMetadataStorage.Layout storage layout = TokenMetadataStorage.layout();
        return layout.name;
    }
    
    function symbol() public view virtual returns (string memory) {
        TokenMetadataStorage.Layout storage layout = TokenMetadataStorage.layout();
        return layout.symbol;
    }

    /*=============
        SETTERS
    =============*/
    
    function _setName(string calldata name_) internal {
        TokenMetadataStorage.layout().name = name_;
    }
    
    function _setSymbol(string calldata symbol_) internal {
        TokenMetadataStorage.layout().symbol = symbol_;
    }

    /*====================
        AUTHORIZATION
    ====================*/
}
