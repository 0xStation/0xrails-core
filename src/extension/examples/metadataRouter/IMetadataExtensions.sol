// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ITokenURIExtension {
    function ext_tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IContractURIExtension {
    function ext_contractURI() external view returns (string memory);
}

interface IMetadataRouter {
    function tokenURI(address contractAddress, uint256 tokenId) external view returns (string memory);
    function contractURI(address contractAddress) external view returns (string memory);
}
