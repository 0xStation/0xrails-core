// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.13;

// import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

// import {ScriptUtils} from "script/utils/ScriptUtils.sol";
// import {ERC6551AccountGroupRails} from "src/cores/ERC6551AccountGroup/ERC6551AccountGroupRails.sol";
// import {ERC6551AccountInitializerSimple} from
//     "src/cores/ERC6551AccountGroup/initializer/ERC6551AccountInitializerSimple.sol";
// import {ERC721AccountRails} from "src/cores/ERC721Account/ERC721AccountRails.sol";

// /// @dev Script to deploy new implementations of BotAccount.sol and CallPermitValidator.sol only.
// /// To deploy a factory enabling permissionless creation of proxy accounts, see BotAccountFactory.s.sol
// contract DeployERC6551AccountGroupScript is ScriptUtils {
//     function run() public {
//         /*=================
//             ENVIRONMENT
//         =================*/

//         /// @dev The following contracts will be deployed and initialized by this script
//         ERC6551AccountGroupRails accountGroupImpl;
//         ERC6551AccountInitializerSimple accountInitializerImpl;
//         ERC721AccountRails erc721AccountImpl;

//         /*===============
//             BROADCAST
//         ===============*/

//         vm.startBroadcast();
//         string memory saltString = ScriptUtils.readSalt("salt");
//         bytes32 salt = bytes32(bytes(saltString));

//         accountGroupImpl = new ERC6551AccountGroupRails{salt: salt}();
//         accountInitializerImpl = new ERC6551AccountInitializerSimple{salt: salt}();
//         erc721AccountImpl = new ERC721AccountRails{salt: salt}(entryPointAddress);

//         ScriptUtils.writeUsedSalt(
//             saltString, string.concat("ERC6551AccountGroupRailsImpl @", Strings.toHexString(address(accountGroupImpl)))
//         );
//         ScriptUtils.writeUsedSalt(
//             saltString,
//             string.concat("ERC6551AccountInitializerSimpleImpl @", Strings.toHexString(address(accountInitializerImpl)))
//         );
//         ScriptUtils.writeUsedSalt(
//             saltString, string.concat("ERC721AccountRailsImpl @", Strings.toHexString(address(erc721AccountImpl)))
//         );

//         vm.stopBroadcast();
//     }
// }
