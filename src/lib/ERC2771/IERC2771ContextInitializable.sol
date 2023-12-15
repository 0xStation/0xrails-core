// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @dev See important notes about `_msgSender()`, `msgData()`, and `_initialize()`
/// in the ERC2771ContextInitializable contract when enabling ERC2771 meta-transactions
interface IERC2771ContextInitializable {
    /// @dev Returns the address of the trusted forwarder
    function trustedForwarder() external view returns (address);
    /// @dev Returns whether a given address is the trusted forwarder
    function isTrustedForwarder(address forwarder) external view returns (bool);
}