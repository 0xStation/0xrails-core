// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable2Step} from "lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {Permissions} from "./Permissions.sol";
import {Operations} from "./examples/Operations.sol";

abstract contract Access is Ownable2Step, Permissions {
    function hasPermission(bytes8 operation, address account) public view override returns (bool) {
        // 3 tiers: has operation permission, has admin permission, or is owner
        if (super.hasPermission(operation, account)) {
            return true;
        }
        if (operation != Operations.ADMIN && super.hasPermission(Operations.ADMIN, account)) {
            return true;
        }
        return account == owner();
    }

    function _checkSenderIsAdmin() internal view {
        _checkPermission(Operations.ADMIN, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
