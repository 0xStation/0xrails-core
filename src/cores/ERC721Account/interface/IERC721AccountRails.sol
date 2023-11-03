// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @notice using the consistent Access layer, expose external functions for interacting with core logic
interface IERC721AccountRails {
    error ImplementationNotApproved(address implementation);
    error AccountChainNFTChainMismatch(uint256 chainId);
    
    /// @dev Initialize the ERC721AccountRails contract with the initialization data.
    /// @param oracle The TelepathyOracle contract for this chain, set on initialization
    /// @param initData Additional initialization data if required by the contract.
    function initialize(address oracle, bytes calldata initData) external;
}
