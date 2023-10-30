// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ScriptUtils} from "lib/protocol-ops/script/ScriptUtils.sol";
import {CallPermitValidator} from "src/validator/CallPermitValidator.sol";
import {BotAccount} from "src/cores/account/BotAccount.sol";
import {BotAccountFactory} from "src/cores/account/factory/BotAccountFactory.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

/// @dev Script to deploy the BotAccountFactory to enable permissionless creation of BotAccounts
/// Creates a CallPermitValidator and the BotAccountFactory implementation and proxy.
/// To deploy standalone BotAccounts, see BotAccount.s.sol
contract BotAccountFactoryScript is ScriptUtils {
    function run() public {
        /*=================
            ENVIRONMENT 
        =================*/

        /// @dev The following contracts will be deployed and initialized by this script
        BotAccountFactory botAccountFactoryImpl;
        BotAccountFactory botAccountFactoryProxy;
        CallPermitValidator callPermitValidator;
        BotAccount botAccountImpl;

        /*===============
            BROADCAST 
        ===============*/

        vm.startBroadcast();

        address entryPointAddress = ScriptUtils.entryPointAddress;

        bytes32 salt = ScriptUtils.create2Salt;
        string memory saltString = Strings.toHexString(uint256(salt), 32);

        address owner = ScriptUtils.symmetry;
        address turnkey = ScriptUtils.turnkey;
        address[] memory turnkeys = new address[](1);
        turnkeys[0] = turnkey;

        // deploy turnkeyValidator
        callPermitValidator = new CallPermitValidator{salt: salt}(entryPointAddress);

        // deploy botAccountImpl for the factory to use
        botAccountImpl = new BotAccount{salt: salt}(entryPointAddress);

        // deploy factoryImpl
        botAccountFactoryImpl = new BotAccountFactory{salt: salt}();

        // craft initData for factoryProxy
        bytes memory botAccountFactoryInitData =
            abi.encodeWithSelector(BotAccountFactory.initialize.selector, address(botAccountImpl), owner);
        // deploy factoryProxy
        botAccountFactoryProxy =
            BotAccountFactory(address(new ERC1967Proxy(address(botAccountFactoryImpl), botAccountFactoryInitData)));

        // Now anyone can permissionlessly deploy a BotAccount like so:
        // BotAccount(payable(botAccountFactoryProxy.createBotAccount(
        //     salt,
        //     owner,
        //     address(callPermitValidator),
        //     turnkeys
        // )));

        logAddress("BotAccountFactoryImpl @", Strings.toHexString(address(botAccountFactoryImpl)));
        logAddress("BotAccountFactoryProxy @", Strings.toHexString(address(botAccountFactoryProxy)));
        logAddress("CallPermitValidator @", Strings.toHexString(address(callPermitValidator)));
        logAddress("BotAccountImpl @", Strings.toHexString(address(botAccountImpl)));

        vm.stopBroadcast();
    }
}
