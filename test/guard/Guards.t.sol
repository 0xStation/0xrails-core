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
        setGuard(operation, address(timeRangeGuard));
        Guard[] memory newGuards = getAllGuards();
        assertEq(guardOf(operation), address(timeRangeGuard));
        assertEq(newGuards.length, 1);
        assertEq(newGuards[0].implementation, address(timeRangeGuard));

        // add guard2
        TimeRangeGuard secondGuard = new TimeRangeGuard();
        setGuard(operation2, address(secondGuard));
        Guard[] memory nowTwoGuards = getAllGuards();
        assertEq(guardOf(operation2), address(secondGuard));
        assertEq(nowTwoGuards.length, 2);
        assertEq(nowTwoGuards[1].implementation, address(secondGuard));
    }

    // `setGuard()` and `_setGuard()` contain a check of EXTCODESIZE opcode, within `_requireContract()`
    // This only causes a revert if those functions are called during the constructor of supplied implementation address
    // Not an issue since `setGuard()` is behind access control mechanisms. No risk of bricking via `selfdestruct()`
    function test_setGuardRevertRequireContract() public {
        vm.expectRevert();
        new MaliciousGuard();
    }

    function test_removeGuard(uint8 numGuards) public {
        // prevent overflow on last numGuards iter
        vm.assume(numGuards != type(uint8).max && numGuards != 0);

        // add existing guard
        bytes8 operation;
        setGuard(operation, address(timeRangeGuard));

        TimeRangeGuard anotherGuard;
        for (uint64 i; i < numGuards;) {
            ++i;
            anotherGuard = new TimeRangeGuard();
            // sufficient to differentiate operations
            setGuard(bytes8(uint64(operation) + i), address(anotherGuard));
        }

        Guard[] memory allGuards = getAllGuards();
        assertEq(allGuards.length, numGuards + 1);

        // remove first guard
        removeGuard(operation);
        assertEq(getAllGuards().length, allGuards.length - 1);
        assertEq(guardOf(operation), address(0x0));

        // remove another guard
        bytes8 newOp = bytes8(uint64(operation) + numGuards);
        removeGuard(newOp);
        uint256 newLength = getAllGuards().length;
        assertEq(newLength, allGuards.length - 2);
        assertEq(guardOf(newOp), address(0x0));

        // remove the rest
        for (uint64 j = uint64(newLength); j > 0;) {
            removeGuard(bytes8(uint64(newOp) - j));
            --j;
        }

        assertEq(getAllGuards().length, 0);
    }

    function test_updateGuard(uint8 numGuards) public {
        // prevent overflow on last numGuards iter
        vm.assume(numGuards != type(uint8).max && numGuards != 0);

        // add existing guard
        bytes8 operation;
        setGuard(operation, address(timeRangeGuard));

        TimeRangeGuard anotherGuard;
        for (uint64 i; i < numGuards;) {
            ++i;
            anotherGuard = new TimeRangeGuard();
            // sufficient to differentiate operations
            setGuard(bytes8(uint64(operation) + i), address(anotherGuard));
        }

        Guard[] memory allGuards = getAllGuards();
        assertEq(allGuards.length, numGuards + 1);

        // update first guard to anotherGuard
        setGuard(operation, address(anotherGuard));
        assertEq(guardOf(operation), address(anotherGuard));

        // update all guards to timeRangeGuard and assert eacha
        for (uint64 i; i < allGuards.length;) {
            bytes8 currentOp = bytes8(uint64(operation) + i);
            setGuard(currentOp, address(timeRangeGuard));
            assertEq(guardOf(currentOp), address(timeRangeGuard));
            ++i;
        }
    }

    function test_checkGuard(bytes8 operation, bytes8 operation2, bytes8 operation3) public {
        // prevent overlapping operations
        vm.assume(operation != operation2 && operation2 != operation3 && operation != operation3);
        setGuard(operation, address(timeRangeGuard));

        // assert timeRangeGuard not setUp- reverts at `getValidTimeRange()` call
        vm.expectRevert("RANGE_UNDEFINED");
        this.checkGuardBefore(operation, "");

        // set up
        timeRangeGuard.setUp(uint40(block.timestamp), type(uint40).max);

        timeRangeGuard.getValidTimeRange(address(this));

        // move forward any amt of blocks to pass `_checkTimeRange()` check on start
        skip(42);
        (address guard, bytes memory checkBeforeData) = this.checkGuardBefore(operation, "");
        assertEq(guard, address(timeRangeGuard));
        this.checkGuardAfter(guard, checkBeforeData, ""); // should not revert

        // autoReject operation3
        setGuard(operation3, autoRejectAddr);

        // operation2 is autoapproved by default
        (guard, checkBeforeData) = this.checkGuardBefore(operation2, "");
        assertEq(guard, address(0x0));
        assertEq(checkBeforeData, "");
        // since operation3 is set to autoReject address, expect GuardRejected error
        err = abi.encodeWithSelector(GuardRejected.selector, operation3, autoRejectAddr);
        vm.expectRevert(err);
        this.checkGuardBefore(operation3, "");
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
// Unrealistic since `setGuard()` should be behind access control mechanisms but good to be aware
// Same possibility for Extensions, also protected by access control
contract MaliciousGuard is IGuard {
    constructor() {
        Guards(msg.sender).setGuard(bytes8("deadbeef"), address(this));
    }

    function contractURI() external view returns (string memory) {}
    function checkBefore(address operator, bytes calldata data) external view returns (bytes memory checkBeforeData) {}
    function checkAfter(bytes calldata checkBeforeData, bytes calldata data) external view {}
}
