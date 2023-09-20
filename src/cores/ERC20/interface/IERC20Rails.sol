// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @notice using the consistent Access layer, expose external functions for interacting with core token logic
interface IERC20Rails {
    /// @dev Function to mint ERC20Rails tokens to a recipient
    /// @param recipient The address of the recipient to receive the minted tokens.
    /// @param amount The amount of tokens to mint and transfer to the recipient.
    /// @return _ Boolean indicating whether the minting and transfer were successful.
    function mintTo(address recipient, uint256 amount) external returns (bool);

    /// @dev Burn ERC20Rails tokens from an address.
    /// @param from The address from which the tokens will be burned.
    /// @param amount The amount of tokens to burn from the sender's balance.
    /// @return _ Boolean indicating whether the burning was successful.
    function burnFrom(address from, uint256 amount) external returns (bool);

    /// @dev Initialize the ERC20Rails contract with the given owner, name, symbol, and initialization data.
    /// @param owner The initial owner of the contract.
    /// @param name The name of the ERC20 token.
    /// @param symbol The symbol of the ERC20 token.
    /// @param initData Additional initialization data if required by the contract.
    function initialize(address owner, string calldata name, string calldata symbol, bytes calldata initData)
        external;
}
