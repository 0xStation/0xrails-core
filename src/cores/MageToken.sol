// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Address} from "openzeppelin-contracts/utils/Address.sol";

import {Mage} from "../Mage.sol";
import {Owner, OwnerInternal} from "../access/owner/Owner.sol";
import {Access} from "../access/Access.sol";
import {Initializer} from "../lib/Initializer/Initializer.sol";

contract MageToken is Mage, Initializer, Owner {
    // owner stored explicitly
    function owner() public view override(Access, OwnerInternal) returns (address) {
        return OwnerInternal.owner();
    }

    // initalize owner and make other calls if needed
    function _initialize(address owner_, bytes calldata initData) internal onlyInitializing {
        if (initData.length > 0) {
            // grant sender owner to ensure they have all permissions for further initialization
            _transferOwnership(msg.sender);
            Address.functionDelegateCall(address(this), initData);
            // if sender and owner arg are different, transfer ownership to desired address
            if (msg.sender != owner_) {
                _transferOwnership(owner_);
            }
        } else {
            _transferOwnership(owner_);
        }
    }
}
