// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ITokenMetadata} from "./ITokenMetadata.sol";
import {TokenMetadataStorage} from "./TokenMetadataStorage.sol";

abstract contract TokenMetadata is ITokenMetadata {
    /*===========
        VIEWS
    ===========*/

    /// @inheritdoc ITokenMetadata
    function name() public view virtual returns (string memory) {
        TokenMetadataStorage.Layout storage layout = TokenMetadataStorage.layout();
        return layout.name;
    }

    /// @inheritdoc ITokenMetadata
    function symbol() public view virtual returns (string memory) {
        TokenMetadataStorage.Layout storage layout = TokenMetadataStorage.layout();
        return layout.symbol;
    }

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

    /*===============
        INTERNALS
    ===============*/

    function _setName(string calldata name_) internal {
        TokenMetadataStorage.layout().name = name_;
        emit NameUpdated(name_);
    }

    function _setSymbol(string calldata symbol_) internal {
        TokenMetadataStorage.layout().symbol = symbol_;
        emit SymbolUpdated(symbol_);
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
