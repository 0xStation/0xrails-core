// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {ISupportsInterface} from "src/lib/ERC165/ISupportsInterface.sol";
import {SupportsInterfaceInternal} from "src/lib/ERC165/SupportsInterfaceInternal.sol";
import {SupportsInterfaceStorage} from "src/lib/ERC165/SupportsInterfaceStorage.sol";
import {SupportsInterface} from "src/lib/ERC165/SupportsInterface.sol";
import {IERC721Receiver} from "src/cores/ERC721/interface/IERC721.sol";
import {InterfaceInternal, InterfaceExternal} from "src/lib/erc7201/Interface.sol";

contract SupportsInterfaceTest is Test, SupportsInterface {

    // existing interfaceId examples from this repo
    bytes4 public ierc721ReceiverId;
    bytes4 public interfaceInternalId;
    bytes4 public interfaceExternalId;

    // to store expected errors
    bytes err;

    function setUp() public {
        ierc721ReceiverId = type(IERC721Receiver).interfaceId;
        interfaceInternalId = type(InterfaceInternal).interfaceId;
        interfaceExternalId = type(InterfaceExternal).interfaceId;
    }

    function test_setUp() public {
        // check storage of `erc165Id` constant on deployment
        bytes4 derivedERC165Id = bytes4(keccak256('supportsInterface(bytes4)'));
        assertEq(derivedERC165Id, bytes4(0x01ffc9a7));
        assertEq(derivedERC165Id, erc165Id);
        assertTrue(supportsInterface(erc165Id));
        assertTrue(supportsInterface(derivedERC165Id));
    }

    function test_addInterface(bytes4 someInterfaceId) public  {
        vm.assume(someInterfaceId != erc165Id);
        vm.assume(someInterfaceId != ierc721ReceiverId);
        vm.assume(someInterfaceId != interfaceInternalId);
        vm.assume(someInterfaceId != interfaceExternalId);

        // test adding existing interfaceIds
        assertFalse(supportsInterface(ierc721ReceiverId));
        _addInterface(ierc721ReceiverId);
        assertTrue(supportsInterface(ierc721ReceiverId));

        assertFalse(supportsInterface(interfaceInternalId));
        _addInterface(interfaceInternalId);
        assertTrue(supportsInterface(interfaceInternalId));

        assertFalse(supportsInterface(interfaceExternalId));
        _addInterface(interfaceExternalId);
        assertTrue(supportsInterface(interfaceExternalId));

        // test adding random interfaceIds
        assertFalse(supportsInterface(someInterfaceId));
        _addInterface(someInterfaceId);
        assertTrue(supportsInterface(someInterfaceId));
    }

    function test_removeInterface(bytes4 someInterfaceId) public  {
        vm.assume(someInterfaceId != erc165Id);
        vm.assume(someInterfaceId != ierc721ReceiverId);
        vm.assume(someInterfaceId != interfaceInternalId);
        vm.assume(someInterfaceId != interfaceExternalId);

        // setup interfaceIds to remove
        _addInterface(ierc721ReceiverId);
        _addInterface(interfaceInternalId);
        _addInterface(interfaceExternalId);
        _addInterface(someInterfaceId);


        // test removing existing interfaceIds
        assertTrue(supportsInterface(ierc721ReceiverId));
        _removeInterface(ierc721ReceiverId);
        assertFalse(supportsInterface(ierc721ReceiverId));

        assertTrue(supportsInterface(interfaceInternalId));
        _removeInterface(interfaceInternalId);
        assertFalse(supportsInterface(interfaceInternalId));

        assertTrue(supportsInterface(interfaceExternalId));
        _removeInterface(interfaceExternalId);
        assertFalse(supportsInterface(interfaceExternalId));

        // test removing random interfaceIds
        assertTrue(supportsInterface(someInterfaceId));
        _removeInterface(someInterfaceId);
        assertFalse(supportsInterface(someInterfaceId));
    }

    /*==============
        OVERRIDES
    ==============*/

    function _checkCanUpdateInterfaces() internal override {}
}
   