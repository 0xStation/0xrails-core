// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC721External} from "./IERC721.sol";
import {ERC721Internal} from "./ERC721Internal.sol";
import {ERC721Storage} from "./ERC721Storage.sol";

abstract contract ERC721 is ERC721Internal, IERC721External {
    /*===========
        VIEWS
    ===========*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return interfaceId == 0x01ffc9a7 // ERC165 interface ID for ERC165.
            || interfaceId == 0x80ac58cd // ERC165 interface ID for ERC721.
            || interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    /*=============
        SETTERS
    =============*/

    function approve(address to, uint256 tokenId) public virtual {
        _approve(to, tokenId);
    }
    
    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        _checkCanTransfer(from, tokenId);
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        transferFrom(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    /*====================
        AUTHORITZATION
    ====================*/
}
