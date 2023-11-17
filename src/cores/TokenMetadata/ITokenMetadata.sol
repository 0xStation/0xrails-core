// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ITokenMetadata {
    // events
    event NameUpdated(string name);
    event SymbolUpdated(string symbol);

    /// @dev Function to return the name of a token implementation
    /// @return _ The returned name string
    function name() external view returns (string calldata);

    /// @dev Function to return the symbol of a token implementation
    /// @return _ The returned symbol string
    function symbol() external view returns (string calldata);

    /// @dev Function to set the name for a token implementation
    /// @param name The name string to set
    function setName(string calldata name) external;

    /// @dev Function to set the symbol for a token implementation
    /// @param symbol The symbol string to set
    function setSymbol(string calldata symbol) external;
}
