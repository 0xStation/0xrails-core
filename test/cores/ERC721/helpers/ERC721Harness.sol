// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "src/cores/ERC721/ERC721.sol";

/// @dev Harness contract wrapping ERC721 to publicly expose internal functions for testing purposes
contract ERC721Harness is ERC721 {

    function name() public pure override returns (string memory) {
        return "ERC721";
    }

    function symbol() public pure override returns (string memory) {
        return "ERC721";
    }
    
    function tokenURI(uint256) public pure override returns (string memory) {
        return "uri";
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function mint(address to, uint256 quantity) public {
        _mint(to, quantity);
    }
    
    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function transfer(address from, address to, uint256 tokenId) public {
        _transfer(from, to, tokenId);
    }

    function safeMint(address to, uint256 quantity) public {
        _safeMint(to, quantity);
    }

    function safeTransfer(address from, address to, uint256 tokenId, bytes memory data) public {
        _safeTransfer(from, to, tokenId, data);
    }

    function checkCanTransfer(address account, uint256 tokenId) public {
        _checkCanTransfer(account, tokenId);
    }

    function checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) public {
        _checkOnERC721Received(from, to, tokenId, data);
    }
}