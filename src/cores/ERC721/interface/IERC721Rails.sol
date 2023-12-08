// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @notice using the consistent Access layer, expose external functions for interacting with core token logic
interface IERC721Rails {
    /// @dev Function to mint ERC721Rails tokens to a recipient
    /// @param recipient The address of the recipient to receive the minted tokens.
    /// @param quantity The amount of tokens to mint and transfer to the recipient.
    function mintTo(address recipient, uint256 quantity) external returns (uint256 mintStartTokenId);

    /// @dev Burn ERC721Rails tokens from the caller.
    /// @param tokenId The ID of the token to burn from the sender's balance.
    function burn(uint256 tokenId) external;

    /// @dev Initialize the ERC721Rails contract with the given owner, name, symbol, and initialization data.
    /// @param owner The initial owner of the contract.
    /// @param name The name of the ERC721 token.
    /// @param symbol The symbol of the ERC721 token.
    /// @param initData Additional initialization data if required by the contract.
    /// @param forwarder The ERC2771 trusted forwarder used to enable gasless meta transactions.
    function initialize(address owner, string calldata name, string calldata symbol, bytes calldata initData, address forwarder)
        external;
}
