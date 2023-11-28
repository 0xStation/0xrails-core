// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC1967Upgrade} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Upgrade.sol";
import {Proxy} from "openzeppelin-contracts/proxy/Proxy.sol";
import {ERC6551AccountLib} from "src/lib/ERC6551/lib/ERC6551AccountLib.sol";

import {IERC6551AccountInitializer} from "./interface/IERC6551AccountInitializer.sol";
import {IERC6551AccountGroup} from "./interface/IERC6551AccountGroup.sol";

/// @notice Global Account Proxy to establish if an ERC6551 Account is using the Account Group pattern.
/// This contract is meant to be a permissionless singleton.
contract AccountProxy is Proxy, ERC1967Upgrade, IERC6551AccountInitializer {
    /// @dev should we enforceme that this function can only be delegatecall'ed?
    function initializeAccount(address, bytes memory) external payable {
        // parse accountGroup from first 20 bytes of 6551 Account salt
        address accountGroup = address(bytes20(bytes32(ERC6551AccountLib.salt())));
        // fetch initializer for this account from the account group
        address initializer = IERC6551AccountGroup(accountGroup).getAccountInitializer(address(this));
        // delegate call initializer with received implementation and initialization data
        _delegate(initializer);
    }

    function _implementation() internal view virtual override returns (address) {
        return ERC1967Upgrade._getImplementation();
    }
}
