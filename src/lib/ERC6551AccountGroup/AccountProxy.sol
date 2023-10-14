// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC6551AccountLib} from "lib/erc6551/src/lib/ERC6551AccountLib.sol";
import {IERC6551AccountInitializer} from "./interface/IERC6551AccountInitializer.sol";
import {IERC6551AccountGroup} from "./interface/IERC6551AccountGroup.sol";

/// @notice Global Account Proxy to establish if an ERC6551 Account is using the Account Group pattern.
/// This contract is meant to be a permissionless singleton.
contract AccountProxy is ERC1967Proxy, IERC6551AccountInitializer {
    constructor() ERC1967Proxy(address(0), "") {}

    /// @dev should we enforceme that this function can only be delegatecall'ed?
    function initializeAccount(address, bytes memory) external payable {
        // parse accountGroup from first 20 bytes of 6551 Account salt
        address accountGroup = address(bytes20(bytes32(ERC6551AccountLib.salt())));
        // fetch initializer for this account from the account group
        address initializer = IERC6551AccountGroup(accountGroup).getAccountInitializer(address(this));
        // delegate call initializer with received implementation and initialization data
        _delegate(initializer);
    }
}
