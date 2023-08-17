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
        assertEq(erc721.totalMinted(), quantity);
    }

    function test_mintRevertZeroQuantity(address to) public {
        vm.expectRevert(IERC721Internal.MintZeroQuantity.selector);
        erc721.mint(to, 0);
        assertEq(erc721.totalMinted(), 0);
    }

    function test_mintRevertZeroAddress(uint8 quantity) public {
        vm.assume(quantity != 0);
        vm.expectRevert(IERC721Internal.MintToZeroAddress.selector);
        erc721.mint(address(0x0), quantity);
        assertEq(erc721.totalMinted(), 0);
    }

    function test_safeMint(uint8 quantity) public {
        vm.assume(quantity > 0);
        
        address to = address(erc721Receiver);
        erc721.safeMint(to, quantity);

        assertEq(erc721.totalSupply(), quantity);
        assertEq(erc721.balanceOf(to), quantity);
        for (uint tokenId; tokenId < quantity; tokenId++) {
            assertEq(erc721.ownerOf(tokenId), to);
        }
        assertEq(erc721.totalMinted(), quantity);
    }

    function test_safeMintRevertTransferToNonERC721Receiver(uint8 quantity) public {
        vm.assume(quantity > 0);
        
        address to = address(this); // test contract doesn't implement onERC721Received()
        err = abi.encodeWithSelector(IERC721Internal.TransferToNonERC721ReceiverImplementer.selector);
        vm.expectRevert(err);
        erc721.safeMint(to, quantity);

        assertEq(erc721.totalSupply(), 0);
        assertEq(erc721.balanceOf(to), 0);
        assertEq(erc721.totalMinted(), 0);

        address to2 = address(new ERC721Harness()); // erc721 contract doesn't implement onERC721Received()
        vm.expectRevert(err);
        erc721.safeMint(to2, quantity);

        assertEq(erc721.totalSupply(), 0);
        assertEq(erc721.balanceOf(to2), 0);
        assertEq(erc721.totalMinted(), 0);
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
        assertEq(erc721.totalBurned(), burnQuantity);
    }

    function test_transfer(address from, address to, uint8 mintQuantity, uint8 transferQuantity) public {
        vm.assume(from != address(0x0) && from != to); // prevent mint to address(0x0) and self transfer
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

    function test_transferSelf(address from, uint8 mintQuantity, uint8 transferQuantity) public {
        vm.assume(from != address(0x0)); // prevent mint to address(0x0) 
        vm.assume(mintQuantity > 0);
        vm.assume(transferQuantity < mintQuantity);

        erc721.mint(from, mintQuantity);

        address to = from;
        uint256 preTransferBalanceFrom = erc721.balanceOf(from);
        uint256 preTransferBalanceTo = erc721.balanceOf(to);
        for (uint i; i < transferQuantity; i++) {
            uint256 tokenId = i;
            erc721.transfer(from, to, tokenId);
            assertEq(erc721.balanceOf(to), preTransferBalanceTo);
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
        uint8 mintQuantity, 
        uint8 transferQuantity
    ) public {
        vm.assume(from != address(0x0));
        vm.assume(transferQuantity < mintQuantity);

        address to = address(this); // test contract doesn't implement onERC721Received()
        erc721.mint(from, mintQuantity);

        uint256 preTransferBalanceFrom = erc721.balanceOf(from);
        uint256 preTransferBalanceTo = erc721.balanceOf(to);
        err = abi.encodeWithSelector(IERC721Internal.TransferToNonERC721ReceiverImplementer.selector);
        // attempt safeTransfers to this address
        for (uint i; i < transferQuantity; i++) {
            uint256 tokenId = i;
            vm.expectRevert(err);
            erc721.safeTransfer(from, to, tokenId, '');
            // assert transfers not completed
            assertEq(erc721.balanceOf(from), preTransferBalanceFrom);
            assertEq(erc721.balanceOf(to), preTransferBalanceTo);
            assertEq(erc721.ownerOf(tokenId), from);
        }

        // attempt safeTransfers to another non onERC721Received() implementer
        address to2 = address(new ERC721Harness());
        uint256 preTransferBalanceTo2 = erc721.balanceOf(to2);
        for (uint i; i < transferQuantity; i++) {
            uint256 tokenId = i;
            vm.expectRevert(err);
            erc721.safeTransfer(from, to2, tokenId, '');
            // assert transfers not completed
            assertEq(erc721.balanceOf(from), preTransferBalanceFrom);
            assertEq(erc721.balanceOf(to2), preTransferBalanceTo2);
            assertEq(erc721.ownerOf(tokenId), from);
        }
        assertEq(erc721.totalSupply(), preTransferBalanceFrom);        
    }

    function test_approve(
        address from, 
        address operator, 
        uint8 mintQuantity
    ) public {
        vm.assume(from != address(0x0) && operator != address(0x0)); // prevent mint/approve to address(0x0)
        vm.assume(mintQuantity > 0);

        erc721.mint(from, mintQuantity);

        for (uint256 i; i < mintQuantity; ++i) {
            // no approvals yet
            assertEq(erc721.getApproved(i), address(0x0));
            assertFalse(erc721.isApprovedForAll(from, operator));

            // make approval
            vm.prank(from);
            erc721.approve(operator, i);

            // assert successful approval
            assertEq(erc721.getApproved(i), operator);
            assertFalse(erc721.isApprovedForAll(from, operator));
        }
    }
    function test_approveRevertApprovalInvalidOperator(address from, uint8 mintQuantity) public {
        vm.assume(from != address(0x0)); // prevent mint/approve to address(0x0)
        vm.assume(mintQuantity > 0);

        address operator = address(0x0); // reverting operator
        erc721.mint(from, mintQuantity);

        for (uint256 i; i < mintQuantity; ++i) {
            // no approvals yet
            assertEq(erc721.getApproved(i), address(0x0));
            assertFalse(erc721.isApprovedForAll(from, operator));

            // make reverting approval
            err = abi.encodeWithSelector(IERC721Internal.ApprovalInvalidOperator.selector);
            vm.expectRevert(err);
            vm.prank(from);
            erc721.approve(operator, i);

            assertEq(erc721.getApproved(i), address(0x0));
            assertFalse(erc721.isApprovedForAll(from, operator));
        }
    }

    function test_approveRevertApprovalCallerNotOwnerNorApproved(
        address from, 
        address someAddress, 
        address operator,
        uint8 mintQuantity
    ) public {
        vm.assume(from != address(0x0) && from != someAddress); // prevent address(0x0) & self-approve
        vm.assume(mintQuantity > 0);

        erc721.mint(from, mintQuantity);

        for (uint256 i; i < mintQuantity; ++i) {
            // no approvals yet
            assertEq(erc721.getApproved(i), address(0x0));
            assertFalse(erc721.isApprovedForAll(from, someAddress));

            // make reverting approval as someAddress
            err = abi.encodeWithSelector(IERC721Internal.ApprovalCallerNotOwnerNorApproved.selector);
            vm.expectRevert(err);
            vm.prank(someAddress);
            erc721.approve(operator, i);

            // assert no approvals made
            assertEq(erc721.getApproved(i), address(0x0));
            assertFalse(erc721.isApprovedForAll(from, operator));
        }
    }

    function test_setApprovalForAll(address from, address operator, uint8 mintQuantity) public {
        vm.assume(from != address(0x0) && operator != address(0x0)); // prevent address(0x0) approvals
        vm.assume(mintQuantity > 0);
  
        erc721.mint(from, mintQuantity);

        // no approval yet
        assertFalse(erc721.isApprovedForAll(from, operator));

        vm.prank(from);
        erc721.setApprovalForAll(operator, true);

        // assert approvalForAll set to true
        assertTrue(erc721.isApprovedForAll(from, operator));
    }

    function test_setApprovalForAllRevertApprovalInvalidOperator(
        address from, 
        uint8 mintQuantity
    ) public {
        vm.assume(from != address(0x0)); // prevent address(0x0) mint
        vm.assume(mintQuantity > 0);
  
        address badOperator = address(0x0);
        erc721.mint(from, mintQuantity);

        // no approval yet
        assertFalse(erc721.isApprovedForAll(from, badOperator));

        err = abi.encodeWithSelector(IERC721Internal.ApprovalInvalidOperator.selector);
        vm.expectRevert(err);
        vm.prank(from);
        erc721.setApprovalForAll(badOperator, true);

        // assert setApprovalForAll failed
        assertFalse(erc721.isApprovedForAll(from, badOperator));
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