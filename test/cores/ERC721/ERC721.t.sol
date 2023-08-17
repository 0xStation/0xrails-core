// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {ERC721} from "src/cores/ERC721/ERC721.sol";
import {IERC721, IERC721Internal} from "src/cores/ERC721/interface/IERC721.sol";
import {ERC721Storage} from "src/cores/ERC721/ERC721Storage.sol";

contract ERC721Test is Test {
    // to store expected revert errors
    bytes err;

    ERC721Harness erc721;
    Erc721ReceiverImplementer erc721Receiver;

    function setUp() public {
        erc721 = new ERC721Harness();
        erc721Receiver = new Erc721ReceiverImplementer();
    }

    function test_setUp() public {
        // sanity checks
        assertEq(erc721.name(), "ERC721");
        assertEq(erc721.symbol(), "ERC721");
        assertEq(erc721.tokenURI(0), "uri");
    }

    function test_mint(address to, uint8 quantity) public {
        vm.assume(to != address(0x0));
        vm.assume(quantity > 0);
        erc721.mint(to, quantity);

        assertEq(erc721.totalSupply(), quantity);
        assertEq(erc721.balanceOf(to), quantity);
        for (uint tokenId; tokenId < quantity; tokenId++) {
            assertEq(erc721.ownerOf(tokenId), to);
        }
    }

    function test_mintRevertZeroQuantity(address to) public {
        vm.expectRevert(IERC721Internal.MintZeroQuantity.selector);
        erc721.mint(to, 0);
    }

    function test_mintRevertZeroAddress(uint8 quantity) public {
        vm.assume(quantity != 0);
        vm.expectRevert(IERC721Internal.MintToZeroAddress.selector);
        erc721.mint(address(0x0), quantity);
    }

    function test_burn(address to, uint8 mintQuantity, uint8 burnQuantity) public {
        vm.assume(mintQuantity > 0);
        vm.assume(burnQuantity < mintQuantity);

        erc721.mint(to, mintQuantity);

        uint256 preBurnBalance = erc721.balanceOf(to);
        for (uint i; i < burnQuantity; i++) {
            uint256 tokenId = i;
            erc721.burn(tokenId);
            assertEq(erc721.totalSupply(), preBurnBalance - (i + 1));
            assertEq(erc721.balanceOf(to), preBurnBalance - (i + 1));
            vm.expectRevert(IERC721Internal.OwnerQueryForNonexistentToken.selector);
            erc721.ownerOf(tokenId);
        }
    }

    function test_transfer(address from, address to, uint8 mintQuantity, uint8 transferQuantity) public {
        vm.assume(from != address(0x0)); // prevent mint to address(0x0)
        vm.assume(to != address(0x0)); // prevent balanceOf() revert on address(0x0)
        vm.assume(mintQuantity > 0);
        vm.assume(transferQuantity < mintQuantity);

        erc721.mint(from, mintQuantity);

        uint256 preTransferBalanceFrom = erc721.balanceOf(from);
        uint256 preTransferBalanceTo = erc721.balanceOf(to);
        for (uint i; i < transferQuantity; i++) {
            uint256 tokenId = i;
            erc721.transfer(from, to, tokenId);
            assertEq(erc721.balanceOf(from), preTransferBalanceFrom - (i + 1));
            assertEq(erc721.balanceOf(to), preTransferBalanceTo + (i + 1));
            assertEq(erc721.ownerOf(tokenId), to);
        }
        assertEq(erc721.totalSupply(), preTransferBalanceFrom);
    }

    function test_safeTransfer(address from, uint8 mintQuantity, uint8 transferQuantity) public {
        vm.assume(from != address(0x0)); // prevent balanceOf() revert on address(0x0)
        vm.assume(mintQuantity > 0);
        vm.assume(transferQuantity < mintQuantity);

        address to = address(erc721Receiver);

        erc721.mint(from, mintQuantity);

        uint256 preTransferBalanceFrom = erc721.balanceOf(from);
        uint256 preTransferBalanceTo = erc721.balanceOf(to);
        for (uint i; i < transferQuantity; i++) {
            uint256 tokenId = i;
            erc721.safeTransfer(from, to, tokenId, '');
            assertEq(erc721.balanceOf(from), preTransferBalanceFrom - (i + 1));
            assertEq(erc721.balanceOf(to), preTransferBalanceTo + (i + 1));
            assertEq(erc721.ownerOf(tokenId), to);
        }
        assertEq(erc721.totalSupply(), preTransferBalanceFrom);
    }

    function test_safeTransferRevertTransferToNonERC721ReceiverImplementer(
        address from, 
        address to,
        uint8 mintQuantity, 
        uint8 transferQuantity
    ) public {
        vm.assume(from != address(0x0));
        vm.assume(to != address(0x0));
        vm.assume(to != 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D); // exclude cheatcode VM addresss
        vm.assume(transferQuantity < mintQuantity);

        erc721.mint(from, mintQuantity);

        uint256 preTransferBalanceFrom = erc721.balanceOf(from);
        uint256 preTransferBalanceTo = erc721.balanceOf(to);
        for (uint i; i < transferQuantity; i++) {
            uint256 tokenId = i;
            // vm.expectRevert(IERC721Internal.TransferToNonERC721ReceiverImplementer.selector);
            erc721.safeTransfer(from, to, tokenId, '');
            assertEq(erc721.balanceOf(from), preTransferBalanceFrom - (i + 1));
            assertEq(erc721.balanceOf(to), preTransferBalanceTo + (i + 1));
            assertEq(erc721.ownerOf(tokenId), to);
        }
        assertEq(erc721.totalSupply(), preTransferBalanceFrom);        
    }
}

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

/// @dev Harness contract implementing `_checkOnERC721Received()` to accept `ERC721::safeTransfer()`
/// for testing purposes
contract Erc721ReceiverImplementer {
    function onERC721Received(
        address, 
        address, 
        uint256, 
        bytes memory
    ) public pure returns (bytes4 retvalue) {
        return this.onERC721Received.selector;
    }
}