// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {TurnkeyValidator} from "src/lib/ERC4337/validator/TurnkeyValidator.sol";
import {BotAccount} from "src/lib/ERC4337/account/BotAccount.sol";

/// @dev Script to deploy new implementations of BotAccount.sol and TurnkeyValidator.sol only.
/// To deploy accounts as proxies, see AccountFactory.sol
contract BotAccountScript is Script {
    function run() public {

        /*=================
            ENVIRONMENT 
        =================*/

        TurnkeyValidator turnkeyValidator;
        BotAccount botAccount;

        // address frog = 0xE7affDB964178261Df49B86BFdBA78E9d768Db6D;
        address sym = 0x7ff6363cd3A4E7f9ece98d78Dd3c862bacE2163d;
        // address paprika = 0x4b8c47aE2e5083EE6AA9aE2884E8051c2e4741b1;
        // address robriks = 0x5d5d4d04B70BFe49ad7Aac8C4454536070dAf180;
        
        // most recent version across goerli, polygon, optimism, arbitrum, mainnet as of 08/31/23
        address entryPointAddress = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;

        // valid as of 08/31/23
        address turnkey = 0xBb942519A1339992630b13c3252F04fCB09D4841;

        uint256 deployerPrivateKey = vm.envUint("PK");

        /*===============
            BROADCAST 
        ===============*/

        vm.startBroadcast(deployerPrivateKey);

        address owner = sym;
        address[] memory turnkeys = new address[](1);
        turnkeys[0] = turnkey;

        turnkeyValidator = new TurnkeyValidator(entryPointAddress);
        botAccount = new BotAccount(entryPointAddress);

        vm.stopBroadcast();
    }
}