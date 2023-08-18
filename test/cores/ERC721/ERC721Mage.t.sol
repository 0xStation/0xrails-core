// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC721Mage} from "src/cores/ERC721/ERC721Mage.sol";
import {Operations} from "src/lib/Operations.sol";
import {Permissions} from "src/access/permissions/Permissions.sol";
import {Guards} from "src/guard/Guards.sol";
import {MetadataRouterExtension} from "src/extension/examples/metadataRouter/MetadataRouterExtension.sol";
import {Extensions} from "src/extension/Extensions.sol";
import {TimeRangeGuard} from "src/guard/examples/TimeRangeGuard.sol";
import {ERC721ReceiverImplementer} from "test/cores/ERC721/helpers/ERC721ReceiverImplementer.sol";

contract ERC721MageTest is Test {

    address public owner;
    address public metadataOperator;
    string public name;
    string public symbol;
    bytes public initData;

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
}