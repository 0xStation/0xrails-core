// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {AccountProxy} from "src/lib/ERC6551AccountGroup/AccountProxy.sol";

/// @dev Script to deploy the AccountProxy singleton for ERC6551 Account Groups.
contract AccountProxyScript is Script {
    function run() public {
        vm.startBroadcast();

        bytes32 salt = 0x6551655165516551655165516551655165516551655165516551655165516551;
        new AccountProxy{salt: salt}(); // deploys to 0xEe0B927F5065923D49dda69dCE229EF467663310

        vm.stopBroadcast();
    }
}
