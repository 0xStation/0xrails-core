// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC4337} from "./IERC4337.sol";
import {ERC4337Storage} from "./ERC4337Storage.sol";

abstract contract ERC4337Internal is IERC4337 {

    /// @dev View function to get the ERC-4337 EntryPoint contract address for this chain
    function entryPoint() public view virtual returns (address) {
        ERC4337Storage.Layout storage layout = ERC4337Storage.layout();
        return layout.entryPoint;
    }

    /// @dev View function to limit callers to only the EntryPoint contract of this chain
    function _checkSenderIsEntryPoint() internal view {
        if (msg.sender != entryPoint()) revert NotEntryPoint(msg.sender);
    }
}