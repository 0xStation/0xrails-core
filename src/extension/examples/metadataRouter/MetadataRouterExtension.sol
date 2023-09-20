// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Extension} from "../../Extension.sol";
import {IContractURIExtension, ITokenURIExtension, IMetadataRouter} from "./IMetadataExtensions.sol";
import {MetadataRouterExtensionData} from "./MetadataRouterExtensionData.sol";

contract MetadataRouterExtension is
    Extension,
    MetadataRouterExtensionData,
    ITokenURIExtension,
    IContractURIExtension
{
    /*===============
        EXTENSION
    ===============*/

    /// @inheritdoc Extension
    function getAllSelectors() public pure override returns (bytes4[] memory selectors) {
        selectors = new bytes4[](2);
        selectors[0] = this.ext_tokenURI.selector;
        selectors[1] = this.ext_contractURI.selector;
        return selectors;
    }

    /// @inheritdoc Extension
    function signatureOf(bytes4 selector) public pure override returns (string memory) {
        if (selector == this.ext_tokenURI.selector) {
            return "ext_tokenURI(uint256)";
        } else if (selector == this.ext_contractURI.selector) {
            return "ext_contractURI()";
        } else {
            return "";
        }
    }

    /// @dev Returns the contract URI for this contract, a modern standard for NFTs
    /// @notice The returned contractURI string is empty in this case.
    function contractURI() external pure returns (string memory uri) {
        return "";
    }

    /*===============
        FUNCTIONS
    ===============*/

    /// @inheritdoc ITokenURIExtension
    function ext_tokenURI(uint256 tokenId) external view returns (string memory) {
        return IMetadataRouter(_getMetadataRouter()).tokenURI(address(this), tokenId);
    }

    /// @inheritdoc IContractURIExtension
    function ext_contractURI() external view returns (string memory) {
        return IMetadataRouter(_getMetadataRouter()).contractURI(address(this));
    }
}
