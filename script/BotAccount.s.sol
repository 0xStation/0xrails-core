// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ScriptUtils} from "script/utils/ScriptUtils.sol";
import {CallPermitValidator} from "src/validator/CallPermitValidator.sol";
import {BotAccount} from "src/cores/account/BotAccount.sol";
import {BotAccountFactory} from "src/cores/account/factory/BotAccountFactory.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

/// @dev Script to deploy new implementations of BotAccount.sol and CallPermitValidator.sol only.
/// To deploy a factory enabling permissionless creation of proxy accounts, see BotAccountFactory.s.sol
contract BotAccountScript is ScriptUtils {
    function run() public {
        /*=================
            ENVIRONMENT 
        =================*/

        /// @dev The following contracts will be deployed and initialized by this script
        CallPermitValidator callPermitValidator;
        BotAccount botAccountImpl;
        BotAccount botAccountProxy;

        // uncomment all instances of `deployerPrivateKey` if using a private key in shell env var
        // uint256 deployerPrivateKey = vm.envUint("PK");

        /*===============
            BROADCAST 
        ===============*/

        vm.startBroadcast( /*deployerPrivateKey*/ );

        address entryPointAddress = ScriptUtils.entryPointAddress;
        string memory saltString = ScriptUtils.readSalt("salt");
        bytes32 salt = bytes32(bytes(saltString));

        address owner = ScriptUtils.stationFounderSafe;
        address turnkey = ScriptUtils.turnkey;
        address[] memory turnkeys = new address[](1);
        turnkeys[0] = turnkey;

        // deploy turnkeyValidator
        callPermitValidator = new CallPermitValidator{salt: salt}(entryPointAddress);

        // deploy botAccountImpl, `_disableInitializers()` called in constructor
        botAccountImpl = new BotAccount{salt: salt}(entryPointAddress);

        // deploy and initialize the botAccountProxy
        botAccountProxy = BotAccount(payable(address(new ERC1967Proxy{salt: salt}(address(botAccountImpl), ''))));
        botAccountProxy.initialize(owner, address(callPermitValidator), turnkeys);

        // the two previous calls are external so they are broadcast as separate txs; thus check state externally
        if (!botAccountProxy.initialized()) revert Create2Failure();

        writeUsedSalt(
            saltString, string.concat("CallPermitValidator @", Strings.toHexString(address(callPermitValidator)))
        );
        writeUsedSalt(saltString, string.concat("BotAccountImpl @", Strings.toHexString(address(botAccountImpl))));
        writeUsedSalt(saltString, string.concat("BotAccountProxy @", Strings.toHexString(address(botAccountProxy))));

        vm.stopBroadcast();
    }
}
