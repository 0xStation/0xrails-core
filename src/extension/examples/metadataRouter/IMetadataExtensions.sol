// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ITokenURIExtension {
    /// @dev Function to extend the `tokenURI()` function
    /// @notice Intended to be invoked in the context of a delegatecall
    function ext_tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IContractURIExtension {
    /// @dev Function to extend the `contractURI()` function
    /// @notice Intended to be invoked in the context of a delegatecall
    function ext_contractURI() external view returns (string memory);
}

interface IMetadataRouter {
    /// @dev Returns the token URI
    /// @return '' The returned tokenURI string
    function tokenURI(address contractAddress, uint256 tokenId) external view returns (string memory);
    
    /// @dev Returns the contract URI, a modern standard for NFTs
    /// @return '' The returned contractURI string
    function contractURI(address contractAddress) external view returns (string memory);
}
