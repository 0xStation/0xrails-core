// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @notice using the consistent Access layer, expose external functions for interacting with core token logic
interface IERC1155Rails {
    /// @dev Function to mint ERC1155Rails tokens to a recipient
    /// @param recipient The address of the recipient to receive the minted tokens.
    /// @param tokenId The ID of the token to mint and transfer to the recipient.
    /// @param value The value of the given tokenId to mint and transfer to the recipient.
    function mintTo(address recipient, uint256 tokenId, uint256 value) external;

    /// @dev Function to burn ERC1155Rails tokens from an address.
    /// @param from The address from which to burn tokens.
    /// @param tokenId The ID of the token to burn from the sender's balance.
    /// @param value The value of the given tokenId to burn from the given address.
    function burnFrom(address from, uint256 tokenId, uint256 value) external;

    /// @dev Initialize the ERC1155Rails contract with the given owner, name, symbol, and initialization data.
    /// @param owner The initial owner of the contract.
    /// @param name The name of the ERC1155 token.
    /// @param symbol The symbol of the ERC1155 token.
    /// @param initData Additional initialization data if required by the contract.
    function initialize(address owner, string calldata name, string calldata symbol, bytes calldata initData)
        external;
}
