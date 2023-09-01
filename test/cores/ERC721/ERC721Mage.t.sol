// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC721Mage} from "src/cores/ERC721/ERC721Mage.sol";
import {IERC721, IERC721Internal} from "src/cores/ERC721/interface/IERC721.sol";
import {Operations} from "src/lib/Operations.sol";
import {Permissions} from "src/access/permissions/Permissions.sol";
import {IPermissions, IPermissionsInternal} from "src/access/permissions/interface/IPermissions.sol";
import {Guards} from "src/guard/Guards.sol";
import {IGuards} from "src/guard/interface/IGuards.sol";
import {MetadataRouterExtension} from "src/extension/examples/metadataRouter/MetadataRouterExtension.sol";
import {Extensions} from "src/extension/Extensions.sol";
import {IExtensions} from "src/extension/interface/IExtensions.sol";
import {TimeRangeGuard} from "src/guard/examples/TimeRangeGuard.sol";
import {ERC721ReceiverImplementer} from "test/cores/ERC721/helpers/ERC721ReceiverImplementer.sol";
import {MockAccountDeployer} from "test/lib/MockAccount.sol";

contract ERC721MageTest is Test, MockAccountDeployer {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    address public owner;
    address public metadataOperator;
    string public name;
    string public symbol;
    bytes public initData;
    bytes4 public constant erc721InterfaceId = 0x80ac58cd; // type(IERC721).interfaceId
    bytes4 public constant erc721MetadataInterfaceId = 0x5b5e139f; // type(IERC721Metadata).interfaceId
    bytes4 public constant extensionsInterfaceId = 0x7e5e9370; // type(IExtensions).interfaceId
    bytes4 public constant guardsInterfaceId = 0x422dae82; // type(IGuards).interfaceId
    bytes4 public constant permissionsInterfaceId = 0x6d0a9f2d; // type(IPermissions).interfaceId

    ERC721Mage public erc721MageImpl;
    ERC721Mage public erc721MageProxy; // ERC1967 proxy wrapped in ERC721Mage for convenience
    MetadataRouterExtension public metadataRouterExtension;
    TimeRangeGuard public timeRangeGuard;
    ERC721ReceiverImplementer public erc721Receiver;

    // to store expected revert errors
    bytes err;

    function setUp() public {
        owner = address(0xbeefEbabe);
        name = "Station";
        symbol = "STN";
        // include empty init data for setup
        initData = abi.encodeWithSelector(
            ERC721Mage.initialize.selector,
            owner,
            name,
            symbol,
            ''
        );

        erc721MageImpl = new ERC721Mage();
        erc721MageProxy = ERC721Mage(payable(address(new ERC1967Proxy(
            address(erc721MageImpl), 
            initData
        ))));
        metadataRouterExtension = new MetadataRouterExtension();
        timeRangeGuard = new TimeRangeGuard();
        erc721Receiver = new ERC721ReceiverImplementer();
    }
    
    function test_setUp() public {
        // assert proxy initialized
        assertEq(erc721MageProxy.owner(), owner);
        assertEq(erc721MageProxy.name(), name);
        assertEq(erc721MageProxy.symbol(), symbol);
        assertTrue(erc721MageProxy.initialized());
        
        // assert implementation initialized but did not receive state updates
        assertEq(erc721MageImpl.owner(), address(0x0));
        assertEq(erc721MageImpl.name(), '');
        assertEq(erc721MageImpl.symbol(), '');
        assertTrue(erc721MageImpl.initialized());
    }

    function test_initializeWithPermission() public {
        ERC721Mage newProxy = ERC721Mage(payable(address(new ERC1967Proxy(address(erc721MageImpl), ''))));

        // configure addPermission() call for metadataOperator
        bytes memory permissionData = abi.encodeWithSelector(
            Permissions.addPermission.selector, 
            Operations.METADATA, 
            metadataOperator
        );
        
        newProxy.initialize(owner, '', '', permissionData);
        
        // assert permission was set with initialize
        assertTrue(newProxy.hasPermission(Operations.METADATA, metadataOperator));
        Permissions.Permission[] memory permissions = newProxy.getAllPermissions();
        assertEq(permissions.length, 1);
        assertEq(permissions[0].operation, Operations.METADATA);
        assertEq(permissions[0].account, metadataOperator);
        assertEq(permissions[0].updatedAt, block.timestamp);
    }

    function test_initializeWithExtension() public {
        ERC721Mage newProxy = ERC721Mage(payable(address(new ERC1967Proxy(address(erc721MageImpl), ''))));

        // configure setExtension() call for metadata extension
        bytes4 uriSelector = MetadataRouterExtension.ext_tokenURI.selector;
        bytes memory extensionData = abi.encodeWithSelector(
            Extensions.setExtension.selector,
            uriSelector,
            address(metadataRouterExtension)
        );
        
        newProxy.initialize(owner, '', '', extensionData);
        assertTrue(newProxy.hasExtended(uriSelector));
        assertEq(newProxy.extensionOf(uriSelector), address(metadataRouterExtension));
        Extensions.Extension[] memory extensions = newProxy.getAllExtensions();
        assertEq(extensions.length, 1);
        assertEq(extensions[0].selector, uriSelector);
        assertEq(extensions[0].implementation, address(metadataRouterExtension));
        assertEq(extensions[0].updatedAt, block.timestamp);
        assertEq(extensions[0].signature, "ext_tokenURI(uint256)");
    }

    function test_initializeWithGuard() public {
        ERC721Mage newProxy = ERC721Mage(payable(address(new ERC1967Proxy(address(erc721MageImpl), ''))));

        // configure setGuard() call for time range guard
        bytes memory guardData = abi.encodeWithSelector(
            Guards.setGuard.selector,
            Operations.MINT,
            address(timeRangeGuard)
        );

        newProxy.initialize(owner, '', '', guardData);
        assertEq(newProxy.guardOf(Operations.MINT), address(timeRangeGuard));
        Guards.Guard[] memory guards = newProxy.getAllGuards();
        assertEq(guards.length, 1);
        assertEq(guards[0].operation, Operations.MINT);
        assertEq(guards[0].implementation, address(timeRangeGuard));
        assertEq(guards[0].updatedAt, block.timestamp);
    }
    
    function test_supportsInterface(bytes4 someInterfaceId) public {
        // check storage of `erc165Id`, `ERC721`, `ERC721Metadata` constants on deployment
        bytes4 derivedERC165Id = bytes4(keccak256('supportsInterface(bytes4)'));
        vm.assume(someInterfaceId != derivedERC165Id);
        vm.assume(someInterfaceId != erc721InterfaceId && someInterfaceId != erc721MetadataInterfaceId);
        vm.assume(someInterfaceId != extensionsInterfaceId && someInterfaceId != guardsInterfaceId && someInterfaceId != permissionsInterfaceId);

        assertEq(derivedERC165Id, bytes4(0x01ffc9a7));
        assertEq(derivedERC165Id, erc721MageProxy.erc165Id());
        assertTrue(erc721MageProxy.supportsInterface(derivedERC165Id));
        assertTrue(erc721MageProxy.supportsInterface(erc721MageProxy.erc165Id()));
        assertTrue(erc721MageProxy.supportsInterface(erc721InterfaceId)); 
        assertTrue(erc721MageProxy.supportsInterface(erc721MetadataInterfaceId)); 

        // test adding random interfaceIds
        assertFalse(erc721MageProxy.supportsInterface(someInterfaceId));
        vm.prank(owner);
        erc721MageProxy.addInterface(someInterfaceId);
        assertTrue(erc721MageProxy.supportsInterface(someInterfaceId));
    }

    function test_addInterfaceRevertPermissionDoesNotExist(bytes4 someInterfaceId) public {
        vm.assume(someInterfaceId != erc721InterfaceId && someInterfaceId != erc721MetadataInterfaceId);
        vm.assume(someInterfaceId != extensionsInterfaceId && someInterfaceId != guardsInterfaceId && someInterfaceId != permissionsInterfaceId);
        vm.assume(someInterfaceId != erc721MageProxy.erc165Id());

        // attempt to addInterface without permission
        assertFalse(erc721MageProxy.supportsInterface(someInterfaceId));
        
        err = abi.encodeWithSelector(IPermissionsInternal.PermissionDoesNotExist.selector, Operations.INTERFACE, address(this));
        vm.expectRevert(err);
        erc721MageProxy.addInterface(someInterfaceId);
        assertFalse(erc721MageProxy.supportsInterface(someInterfaceId));        
    }

    function test_mintTo(uint8 quantity) public {
        vm.assume(quantity != 0);

        address recipient = address(0xdeadbeef);

        assertEq(erc721MageProxy.balanceOf(recipient), 0);
        vm.prank(owner);
        erc721MageProxy.mintTo(recipient, quantity);
        assertEq(erc721MageProxy.balanceOf(recipient), quantity);
        assertEq(erc721MageProxy.totalSupply(), quantity);

        for (uint32 i; i < quantity; ) {
            ++i;
            assertEq(erc721MageProxy.ownerOf(i), recipient);
        }
    }

    function test_mintToRevertZeroQuantity(address to) public {
        vm.assume(to != address(0x0));

        vm.expectRevert(IERC721Internal.MintZeroQuantity.selector);
        vm.prank(owner);
        erc721MageProxy.mintTo(to, 0);

        assertEq(erc721MageProxy.totalMinted(), 0);
        assertEq(erc721MageProxy.totalSupply(), 0);
        assertEq(erc721MageProxy.balanceOf(to), 0);
    }

    function test_mintToRevertZeroAddress(uint8 quantity) public {
        vm.assume(quantity != 0);
        vm.expectRevert(IERC721Internal.MintToZeroAddress.selector);
        vm.prank(owner);
        erc721MageProxy.mintTo(address(0x0), quantity);
        assertEq(erc721MageProxy.totalMinted(), 0);
        assertEq(erc721MageProxy.totalSupply(), 0);
    }

    function test_mintToRevertTransferToNonERC721Receiver(uint8 quantity) public {
        vm.assume(quantity > 0);
        
        address to = address(this); // test contract doesn't implement onERC721Received()
        err = abi.encodeWithSelector(IERC721Internal.TransferToNonERC721ReceiverImplementer.selector);
        vm.expectRevert(err);
        vm.startPrank(owner);
        erc721MageProxy.mintTo(to, quantity);

        assertEq(erc721MageProxy.totalSupply(), 0);
        assertEq(erc721MageProxy.balanceOf(to), 0);
        assertEq(erc721MageProxy.totalMinted(), 0);

        address to2 = address(timeRangeGuard); // guard contract doesn't implement onERC721Received()
        vm.expectRevert(err);
        erc721MageProxy.mintTo(to2, quantity);

        assertEq(erc721MageProxy.totalSupply(), 0);
        assertEq(erc721MageProxy.balanceOf(to2), 0);
        assertEq(erc721MageProxy.totalMinted(), 0);
    }

    function test_burn(uint8 quantity) public {
        vm.assume(quantity != 0);

        address recipient = address(0xdeadbeef);

        assertEq(erc721MageProxy.balanceOf(recipient), 0);
        vm.startPrank(owner);
        erc721MageProxy.mintTo(recipient, quantity);
        assertEq(erc721MageProxy.balanceOf(recipient), quantity);
        assertEq(erc721MageProxy.totalSupply(), quantity);
        assertEq(erc721MageProxy.totalBurned(), 0);

        err = abi.encodeWithSelector(IERC721Internal.OwnerQueryForNonexistentToken.selector);
        for (uint32 i; i < quantity; ) {
            ++i;
            assertEq(erc721MageProxy.ownerOf(i), recipient);

            erc721MageProxy.burn(i);

            vm.expectRevert();
            erc721MageProxy.ownerOf(i);
        }

        assertEq(erc721MageProxy.balanceOf(recipient), 0);
        assertEq(erc721MageProxy.totalSupply(), 0);
        assertEq(erc721MageProxy.totalBurned(), quantity);
    }

    function test_approve(
        address operator, 
        uint8 mintQuantity
    ) public {
        address from = createAccount();
        // prevent mint/approve/delegatecalls to address(0x0)
        vm.assume(from != address(0x0) && from != address(erc721MageProxy));
        vm.assume(operator != address(0x0)); 
        vm.assume(mintQuantity > 0);

        vm.prank(owner);
        erc721MageProxy.mintTo(from, mintQuantity);

        for (uint256 i; i < mintQuantity; ) {
            ++i;
            // no approvals yet
            assertEq(erc721MageProxy.getApproved(i), address(0x0));
            assertFalse(erc721MageProxy.isApprovedForAll(from, operator));

            // make approval
            vm.prank(from);
            erc721MageProxy.approve(operator, i);

            // assert successful approval
            assertEq(erc721MageProxy.getApproved(i), operator);
            assertFalse(erc721MageProxy.isApprovedForAll(from, operator));
        }
    }

    function test_approveRevertApprovalInvalidOperator(address from, uint8 mintQuantity) public {
        vm.assume(from != address(0x0) && from != address(erc721MageProxy)); // prevent mint/approve/delegatecalls to address(0x0)
        vm.assume(mintQuantity > 0);

        address operator = address(0x0); // reverting operator
        vm.prank(owner);
        erc721MageProxy.mintTo(from, mintQuantity);

        for (uint256 i; i < mintQuantity; ) {
            ++i;
            // no approvals yet
            assertEq(erc721MageProxy.getApproved(i), address(0x0));
            assertFalse(erc721MageProxy.isApprovedForAll(from, operator));

            // make reverting approval
            err = abi.encodeWithSelector(IERC721Internal.ApprovalInvalidOperator.selector);
            vm.expectRevert(err);
            vm.prank(from);
            erc721MageProxy.approve(operator, i);

            assertEq(erc721MageProxy.getApproved(i), address(0x0));
            assertFalse(erc721MageProxy.isApprovedForAll(from, operator));
        }
    }

    function test_approveRevertApprovalCallerNotOwnerNorApproved(
        address someAddress, 
        address operator,
        uint8 mintQuantity
    ) public {
        vm.assume(operator != address(0x0));
        vm.assume(mintQuantity > 0);

        address from = address(0xdeadbeef);

        vm.prank(owner);
        erc721MageProxy.mintTo(from, mintQuantity);

        for (uint256 i; i < mintQuantity; ) {
            ++i;
            // no approvals yet
            assertEq(erc721MageProxy.getApproved(i), address(0x0));
            assertFalse(erc721MageProxy.isApprovedForAll(from, someAddress));

            // make reverting approval as someAddress
            err = abi.encodeWithSelector(IERC721Internal.ApprovalCallerNotOwnerNorApproved.selector);
            vm.expectRevert(err);
            vm.prank(someAddress);
            erc721MageProxy.approve(operator, i);

            // assert no approvals made
            assertEq(erc721MageProxy.getApproved(i), address(0x0));
            assertFalse(erc721MageProxy.isApprovedForAll(from, operator));
        }
    }

    function test_setApprovalForAll(address operator, uint8 mintQuantity) public {
        vm.assume(operator != address(0x0)); 
        vm.assume(mintQuantity > 0);

        address from = address(0xdeadbeef);
  
        vm.prank(owner);
        erc721MageProxy.mintTo(from, mintQuantity);

        // no approval yet
        assertFalse(erc721MageProxy.isApprovedForAll(from, operator));

        vm.prank(from);
        erc721MageProxy.setApprovalForAll(operator, true);

        // assert approvalForAll set to true
        assertTrue(erc721MageProxy.isApprovedForAll(from, operator));
    }

    function test_setApprovalForAllRevertApprovalInvalidOperator(uint8 mintQuantity) public {
        vm.assume(mintQuantity > 0);
  
        address from = address(0xdeadbeef);
        address badOperator = address(0x0);
        
        vm.prank(owner);
        erc721MageProxy.mintTo(from, mintQuantity);

        // no approval yet
        assertFalse(erc721MageProxy.isApprovedForAll(from, badOperator));

        err = abi.encodeWithSelector(IERC721Internal.ApprovalInvalidOperator.selector);
        vm.expectRevert(err);
        vm.prank(from);
        erc721MageProxy.setApprovalForAll(badOperator, true);

        // assert setApprovalForAll failed
        assertFalse(erc721MageProxy.isApprovedForAll(from, badOperator));
    }

    function test_transferFrom(
        address operator,
        uint8 mintQuantity, 
        uint8 transferQuantity
    ) public {
        address from = createAccount();
        address to = createAccount();
        // prevent transfers, approvals, delegatecalls to/from address(0x0)
        vm.assume(operator != address(0x0)); 
        vm.assume(from != operator && operator != to);
        vm.assume(from != address(erc721MageProxy));
        vm.assume(mintQuantity > 0);
        vm.assume(transferQuantity < mintQuantity / 3);

        vm.prank(owner);
        erc721MageProxy.mintTo(from, mintQuantity);

        // transferFrom as owner
        vm.startPrank(from);
        uint256 tokenId;
        for (uint256 i; i < transferQuantity; ) {
            ++i;
            assertEq(erc721MageProxy.balanceOf(from), mintQuantity - (i - 1));
            assertEq(erc721MageProxy.balanceOf(to), 0 + (i - 1));

            tokenId = i;
            assertEq(erc721MageProxy.ownerOf(tokenId), from);
            erc721MageProxy.transferFrom(from, to, tokenId);
            
            assertEq(erc721MageProxy.ownerOf(tokenId), to);
            assertEq(erc721MageProxy.balanceOf(from), mintQuantity - i);
            assertEq(erc721MageProxy.balanceOf(to), i);
        }
        vm.stopPrank();
        
        // w/ explicit approve
        for (uint256 j; j < transferQuantity; ) {
            ++j;
            assertEq(erc721MageProxy.balanceOf(from), mintQuantity - transferQuantity - (j - 1));
            assertEq(erc721MageProxy.balanceOf(to), transferQuantity + (j - 1));
            
            tokenId = transferQuantity + j;
            assertEq(erc721MageProxy.ownerOf(tokenId), from);
            
            vm.prank(from);
            erc721MageProxy.approve(operator, tokenId);
            assertEq(erc721MageProxy.getApproved(tokenId), operator);

            vm.prank(operator);
            erc721MageProxy.transferFrom(from, to, tokenId);

            assertEq(erc721MageProxy.ownerOf(tokenId), to);
            assertEq(erc721MageProxy.balanceOf(from), mintQuantity - transferQuantity - j);
            assertEq(erc721MageProxy.balanceOf(to), transferQuantity + j);
        }

        // w/ setApprovalForAll
        assertFalse(erc721MageProxy.isApprovedForAll(from, operator));
        vm.prank(from);
        erc721MageProxy.setApprovalForAll(operator, true);

        for (uint256 k; k < transferQuantity; ) {
            ++k;
            assertEq(erc721MageProxy.balanceOf(from), mintQuantity - transferQuantity * 2 - (k - 1));
            assertEq(erc721MageProxy.balanceOf(to), transferQuantity * 2 + (k - 1));
            
            tokenId = transferQuantity * 2 + k;
            assertEq(erc721MageProxy.ownerOf(tokenId), from);
            assertTrue(erc721MageProxy.isApprovedForAll(from, operator));

            vm.prank(operator);
            erc721MageProxy.transferFrom(from, to, tokenId);

            assertEq(erc721MageProxy.ownerOf(tokenId), to);
            assertEq(erc721MageProxy.balanceOf(from), mintQuantity - transferQuantity * 2 - k);
            assertEq(erc721MageProxy.balanceOf(to), transferQuantity * 2 + k);
        }

        assertEq(erc721MageProxy.totalSupply(), mintQuantity);
        assertEq(erc721MageProxy.totalMinted(), mintQuantity);
    }

    function test_transferFromRevertTransferCallerNotOwnerNorApproved(
        address from,
        address to,
        address badOperator,
        uint8 mintQuantity
    ) public {
        // prevent transfers, approvals to/from address(0x0)
        vm.assume(from != address(0x0) && to != address(0x0)); 
        vm.assume(from != badOperator && from != to);
        vm.assume(mintQuantity > 0);
        vm.assume(badOperator != address(0));

        vm.prank(owner);
        erc721MageProxy.mintTo(from, mintQuantity);

        vm.startPrank(badOperator);
        uint256 tokenId;
        for (uint256 i; i < mintQuantity; ) {
            ++i;
            assertEq(erc721MageProxy.balanceOf(from), mintQuantity);
            assertEq(erc721MageProxy.balanceOf(to), 0);
            
            tokenId = i;
            assertEq(erc721MageProxy.ownerOf(tokenId), from);

            // attempt transferFrom without approval
            err = abi.encodeWithSelector(IERC721Internal.TransferCallerNotOwnerNorApproved.selector);
            vm.expectRevert(err);
            erc721MageProxy.transferFrom(from, to, tokenId);
            
            // assert no state changes made
            assertEq(erc721MageProxy.ownerOf(tokenId), from);
            assertEq(erc721MageProxy.balanceOf(from), mintQuantity);
            assertEq(erc721MageProxy.balanceOf(to), 0);
        }
        vm.stopPrank();
    }
}