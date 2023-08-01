// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Mage} from "src/Mage.sol";
import {ERC721AUpgradeable} from "./ERC721AUpgradeable.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {Address} from "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import {
    ITokenURIExtension, IContractURIExtension
} from "src/extension/examples/metadataRouter/IMetadataExtensions.sol";
import {Operations} from "src/access/examples/Operations.sol";
import {IERC721Mage} from "./interface/IERC721Mage.sol";

/// @notice apply Mage pattern to ERC721 NFTs
/// @dev ERC721A chosen for only practical solution for large token supply allocations
contract ERC721Mage is Mage, ERC721AUpgradeable, IERC721Mage {
    constructor(string memory name, string memory symbol) ERC721A(name, symbol) {}

    /*==============
        METADATA
    ==============*/

    function supportsInterface(bytes4 interfaceId) public view override(Mage, ERC721A) returns (bool) {
        return Mage.supportsInterface(interfaceId) || ERC721A.supportsInterface(interfaceId);
    }

    // must override ERC721A implementation
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // to avoid clashing selectors, use standardized `ext_` prefix
        return ITokenURIExtension(address(this)).ext_tokenURI(tokenId);
    }

    // include contractURI as modern standard for NFTs
    function contractURI() public view override returns (string memory) {
        // to avoid clashing selectors, use standardized `ext_` prefix
        return IContractURIExtension(address(this)).ext_contractURI();
    }

    /*=============
        SETTERS
    =============*/

    function mintTo(address recipient, uint256 quantity) external onlyPermission(Operations.MINT) {
        _safeMint(recipient, quantity);
    }

    function burn(uint256 tokenId) external {
        if (msg.sender != ownerOf(tokenId)) {
            _checkPermission(Operations.BURN, msg.sender);
        }
        _burn(tokenId);
    }

    /*===========
        GUARD
    ===========*/

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        view
        override
    {
        (bytes8 operation, bytes memory data) = _getGuardParams(from, to, startTokenId, quantity);
        checkGuardBefore(operation, data);
    }

    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        view
        override
    {
        (bytes8 operation, bytes memory data) = _getGuardParams(from, to, startTokenId, quantity);
        checkGuardAfter(operation, data);
    }

    function _getGuardParams(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        view
        returns (bytes8 operation, bytes memory data)
    {
        if (from == address(0)) {
            operation = Operations.MINT;
        } else if (to == address(0)) {
            operation = Operations.BURN;
        } else {
            operation = Operations.TRANSFER;
        }
        data = abi.encode(msg.sender, from, to, startTokenId, quantity);

        return (operation, data);
    }
}
