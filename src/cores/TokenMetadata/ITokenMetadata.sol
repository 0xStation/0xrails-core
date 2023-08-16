// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ITokenMetadataInternal {
    // events
    event NameUpdated(string name);
    event SymbolUpdated(string symbol);

    // errors

    // views
    function name() external view returns (string calldata);
    function symbol() external view returns (string calldata);
}

interface ITokenMetadataExternal {
    // setters
    function setName(string calldata name) external;
    function setSymbol(string calldata symbol) external;
}

interface ITokenMetadata is ITokenMetadataInternal, ITokenMetadataExternal {}
