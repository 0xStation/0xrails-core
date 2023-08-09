// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Guards} from "src/guard/Guards.sol";
import {IGuards} from "src/guard/interface/IGuards.sol";
import {TimeRangeGuard} from "src/guard/examples/TimeRangeGuard.sol";
import {GuardsStorage} from "src/guard/GuardsStorage.sol";

import {IGuard} from "src/guard/interface/IGuard.sol";

// This test contract inherits Guards to use this contract as a guards manager
// and test raw functionality. It therefore overrides an abstract unimplemented function
contract GuardsTest is Test, Guards, IGuards {
    using GuardsStorage for address;

    TimeRangeGuard public timeRangeGuard;
    address public autoRejectAddr;
    
    // to store expected revert errors
    bytes err;

    // error from Contract.sol, thrown on `_requireContract()` reverts
    error InvalidContract(address implementation);

    function setUp() public {
        timeRangeGuard = new TimeRangeGuard();
        autoRejectAddr = GuardsStorage.MAX_ADDRESS;
    }

    function test_setUp() public {
        // sanity checks
        assertEq(autoRejectAddr, address(type(uint160).max));
        assertTrue(autoRejectAddr.autoReject());
        assertTrue(address(0x0).autoApprove());
    }

    function test_addGuard(bytes8 operation, bytes8 operation2) public {
        vm.assume(operation != operation2);
        // ensure operation and guard do not yet exist
        address guard = guardOf(operation);
        address guard2 = guardOf(operation2);
        assertEq(guard, address(0x0));
        assertEq(guard2, address(0x0));
        assertEq(getAllGuards().length, 0);

        // add guard
        addGuard(operation, address(timeRangeGuard));
        Guard[] memory newGuards = getAllGuards();
        assertEq(guardOf(operation), address(timeRangeGuard));
        assertEq(newGuards.length, 1);
        assertEq(newGuards[0].implementation, address(timeRangeGuard));

        // add guard2
        TimeRangeGuard secondGuard = new TimeRangeGuard();
        addGuard(operation2, address(secondGuard));
        Guard[] memory nowTwoGuards = getAllGuards();
        assertEq(guardOf(operation2), address(secondGuard));
        assertEq(nowTwoGuards.length, 2);
        assertEq(nowTwoGuards[1].implementation, address(secondGuard));
    }

    // `addGuard()` and `_addGuard()` contain a check of EXTCODESIZE opcode, within `_requireContract()`
    // This only causes a revert if those functions are called during the constructor of supplied implementation address
    // Not an issue since `addGuard()` is behind access control mechanisms, test here for awareness
    function test_addGuardRevertRequireContract(bytes8 operation) public {
        vm.expectRevert();
        MaliciousGuard newGuard = new MaliciousGuard();
    }
    
    function test_removeGuard() public {}

    function test_updateGuard() public {}

    // `_updateGuard()` and `updateGuard()` contain a check of EXTCODESIZE opcode, within `_requireContract()`
    // This only causes a revert if those functions are called during the constructor of supplied implementation address
    function test_updateGuardRevertRequireContract() public {}

    function test_checkGuard() public {
        // checkGuardBefore()
        // checkGuardAfter()
    }

    /*==============
        OVERRIDES
    ==============*/

    function _checkCanUpdateGuards() internal override {}
}

    /*=========
        POC
    =========*/

// PoC contract to demonstrate revert on EXTCODESIZE check
// Unrealistic since `addGuard()` should be behind access control mechanisms but good to be aware
// Same possibility for Extensions, also protected by access control
contract MaliciousGuard is IGuard {
    constructor() {
        Guards(msg.sender).addGuard(bytes8('deadbeef'), address(this));
    }

    function contractURI() external view returns (string memory) {}
    function checkBefore(address operator, bytes calldata data) external view returns (bool) {}
    function checkAfter(address operator, bytes calldata data) external view returns (bool) {}
}