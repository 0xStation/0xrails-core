// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

import {ScriptUtils} from "script/utils/ScriptUtils.sol";
import {ERC6551AccountGroupProxy} from "src/cores/ERC6551AccountGroup/factory/ERC6551AccountGroupProxy.sol";
import {IERC6551AccountGroupRails} from "src/cores/ERC6551AccountGroup/interface/IERC6551AccountGroupRails.sol";

/// @dev Script to deploy new implementations of BotAccount.sol and CallPermitValidator.sol only.
/// To deploy a factory enabling permissionless creation of proxy accounts, see BotAccountFactory.s.sol
contract DeployERC6551AccountGroupProxyScript is ScriptUtils {
    function run() public {
        /*=================
            ENVIRONMENT 
        =================*/

        /// @dev The following contracts will be deployed and initialized by this script
        ERC6551AccountGroupProxy accountGroupProxy;

        address accountGroupImpl = 0x95F2D8faf3dFAb1EBFfEA31A072B440E0028b27D; // arachnid
        address accountInitializerImpl = 0xB41B441CF107Dd860169DbC3198B770FFB81617a; // simple, arachnid

        /*===============
            BROADCAST 
        ===============*/

        vm.startBroadcast();
        // string memory saltString = ScriptUtils.readSalt("salt");
        string memory saltString = "orb";
        bytes32 salt = bytes32(bytes(saltString));

        address owner = symmetry;
        bytes memory initData =
            abi.encodeWithSelector(IERC6551AccountGroupRails.initialize.selector, owner, accountInitializerImpl);
        accountGroupProxy = new ERC6551AccountGroupProxy{salt: salt}(accountGroupImpl, initData);

        ScriptUtils.writeUsedSalt(
            saltString, string.concat("ERC6551AccountGroupProxy @", Strings.toHexString(address(accountGroupProxy)))
        );
        vm.stopBroadcast();
    }
}
