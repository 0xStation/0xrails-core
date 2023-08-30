// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import {IERC4337} from "./IERC4337.sol";
import {ERC4337Storage} from "./ERC4337Storage.sol";

abstract contract ERC4337Internal is IERC4337 {

    function entryPoint() public view virtual returns (address) {
        ERC4337Storage.Layout storage layout = ERC4337Storage.layout();
        return layout.entryPoint;
    }

    function _checkSenderIsEntryPoint() internal view {
        if (msg.sender != entryPoint()) revert NotEntryPoint(msg.sender);
    }
}