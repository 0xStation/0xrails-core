// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ScriptUtils} from "script/utils/ScriptUtils.sol";
import {AccountCollectionRails} from "src/cores/AccountCollection/AccountCollectionRails.sol";
import {AccountInitializerRails} from "src/cores/AccountCollection/AccountInitializerRails.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

/// @dev Script to deploy new implementations of BotAccount.sol and CallPermitValidator.sol only.
/// To deploy a factory enabling permissionless creation of proxy accounts, see BotAccountFactory.s.sol
contract AccountCollectionScript is ScriptUtils {
    function run() public {
        /*=================
            ENVIRONMENT 
        =================*/

        /// @dev The following contracts will be deployed and initialized by this script
        AccountCollectionRails accountCollectionImpl;
        AccountInitializerRails accountInitializerImpl;

        /*===============
            BROADCAST 
        ===============*/

        vm.startBroadcast();
        string memory saltString = ScriptUtils.readSalt("salt");
        bytes32 salt = bytes32(bytes(saltString));

        accountCollectionImpl = new AccountCollectionRails{salt: salt}();
        accountInitializerImpl = new AccountInitializerRails{salt: salt}();

        ScriptUtils.writeUsedSalt(
            saltString,
            string.concat("AccountCollectionRailsImpl @", Strings.toHexString(address(accountCollectionImpl)))
        );
        ScriptUtils.writeUsedSalt(
            saltString,
            string.concat("AccountInitializerRailsImpl @", Strings.toHexString(address(accountInitializerImpl)))
        );

        vm.stopBroadcast();
    }
}
