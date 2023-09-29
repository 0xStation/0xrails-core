// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ScriptUtils} from "script/utils/ScriptUtils.sol";
import {AccountCollectionProxy} from "src/cores/AccountCollection/AccountCollectionProxy.sol";
import {IAccountCollectionRails} from "src/cores/AccountCollection/interface/IAccountCollectionRails.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

/// @dev Script to deploy new implementations of BotAccount.sol and CallPermitValidator.sol only.
/// To deploy a factory enabling permissionless creation of proxy accounts, see BotAccountFactory.s.sol
contract AccountCollectionProxyScript is ScriptUtils {
    function run() public {
        /*=================
            ENVIRONMENT 
        =================*/

        /// @dev The following contracts will be deployed and initialized by this script
        AccountCollectionProxy accountCollectionProxy;
        address accountCollectionImpl = 0x59f11667608Fe802eE3Ed9F0806B72113bCb2249;
        // address accountInitializerImpl = 0xa75C030274a59c3C10761587737823044EE79eb4; // rails
        address accountInitializerImpl = 0xF0315735879845512946Cf0ef7E4fe84294C7112; // simple

        /*===============
            BROADCAST 
        ===============*/

        vm.startBroadcast();
        string memory saltString = ScriptUtils.readSalt("salt");
        bytes32 salt = bytes32(bytes(saltString));

        address owner = symmetry;
        bytes memory initData =
            abi.encodeWithSelector(IAccountCollectionRails.initialize.selector, owner, accountInitializerImpl);
        // accountCollectionProxy = new AccountCollectionProxy{salt: salt}(accountCollectionImpl, initData);
        accountCollectionProxy = new AccountCollectionProxy(accountCollectionImpl, initData);

        ScriptUtils.writeUsedSalt(
            saltString, string.concat("AccountCollectionProxy @", Strings.toHexString(address(accountCollectionProxy)))
        );
        vm.stopBroadcast();
    }
}
