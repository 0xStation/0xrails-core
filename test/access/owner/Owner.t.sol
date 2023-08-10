// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Owner} from "src/access/owner/Owner.sol";
import {OwnerStorage} from "src/access/owner/OwnerStorage.sol";

contract OwnerTest is Test, Owner {
    
    address initialOwner; // to store msg.sender of setUp() deployment

    bytes err;

    // this `setUp()` function assumes contracts that inherit Owner will call `_transferOwnership(msg.sender)` 
    // on deployment, whether within a constructor or proxy `init()` function
    function setUp() public {
        initialOwner = msg.sender;
        _transferOwnership(initialOwner);
    }

    function test_setUp() public returns (bytes32) {
        // sanity checks
        assertEq(owner(), initialOwner);
        OwnerStorage.Layout storage layout = OwnerStorage.layout();
        assertEq(layout.owner, owner());
        assertEq(layout.pendingOwner, address(0x0));
        
        bytes32 slit;
        assembly { slit := layout.slot }
        bytes32 slot = keccak256(abi.encode(uint256(keccak256("mage.Owner")) - 1)); //OwnerStorage.SLOT);
        
        assertEq(slit, slot);
    }

    function test_renounceOwnership() public {
        vm.prank(initialOwner);
        renounceOwnership();

        assertEq(owner(), address(0x0));
        assertEq(pendingOwner(), address(0x0));
        // check storage
        OwnerStorage.Layout storage layout = OwnerStorage.layout();
        assertEq(layout.owner, address(0x0));
        assertEq(layout.pendingOwner, address(0x0));
    }

    function test_transferOwnership(address someAddress) public {
        vm.assume(someAddress != address(0x0) && someAddress != initialOwner);

        vm.prank(initialOwner);
        transferOwnership(someAddress);

        assertEq(owner(), initialOwner); // assert owner remains the same
        assertEq(pendingOwner(), someAddress); // assert pendingOwner set
        // check storage
        OwnerStorage.Layout storage layout = OwnerStorage.layout();
        assertEq(layout.owner, initialOwner);
        assertEq(layout.pendingOwner, someAddress);

        // expect revert for transferOwnership(address(0x0))
        err = abi.encodeWithSelector(OwnerInvalidOwner.selector, address(0x0));
        vm.expectRevert(err);
        transferOwnership(address(0x0));
    }

    function test_acceptOwnership(address someAddress) public {
        vm.assume(someAddress != address(0x0) && someAddress != initialOwner);

        // initiate ownership transfer
        vm.startPrank(initialOwner);
        transferOwnership(someAddress);

        // ensure acceptOwnership() reverts when called as non-pendingOwner
        err = abi.encodeWithSelector(OwnerUnauthorizedAccount.selector, msg.sender);
        vm.expectRevert(err);
        acceptOwnership();

        vm.stopPrank;
        // call as pendingOwner
        vm.prank(someAddress);
        acceptOwnership();

        assertEq(owner(), someAddress);
        assertEq(pendingOwner(), address(0x0));
        // check storage
        OwnerStorage.Layout storage layout = OwnerStorage.layout();
        assertEq(layout.owner, someAddress);
        assertEq(layout.pendingOwner, address(0x0));
    }
}
