// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.13;

// import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

// import {ScriptUtils} from "script/utils/ScriptUtils.sol";
// import {ERC6551AccountGroupProxy} from "src/cores/ERC6551AccountGroup/factory/ERC6551AccountGroupProxy.sol";
// import {IERC6551AccountInitializer} from "src/cores/ERC6551AccountGroup/interface/IERC6551AccountInitializer.sol";
// import {IERC721AccountRails} from "src/cores/ERC721Account/interface/IERC721AccountRails.sol";
// import {IPermissions} from "src/access/permissions/interface/IPermissions.sol";
// import {Operations} from "src/lib/Operations.sol";

// /// @dev Script to deploy new implementations of BotAccount.sol and CallPermitValidator.sol only.
// /// To deploy a factory enabling permissionless creation of proxy accounts, see BotAccountFactory.s.sol
// contract CreateERC6551AccountScript is ScriptUtils {
//     function run() public {
//         /*=================
//             ENVIRONMENT
//         =================*/

//         /// @dev The following contracts will be deployed and initialized by this script
//         address erc6551Registry = 0x02101dfB77FDE026414827Fdc604ddAF224F0921;
//         address accountGroupProxy = 0x7c673cfbb12f335Aa2bB7d340c3902a18F82B081; // 1167-lib, arachnid
//         address accountImpl = 0x0Be252e48e4bEEeAF739736ed93225491FF814e8; // ERC721AccountRails arachnid
//         uint256 tokenChainId = 5;
//         address tokenAddress = 0xd2Ab49b8b94523caE7E1826CFC057Dc1A426772c; // orb goerli
//         uint256 tokenId = 1;
//         uint256 counter = 0;

//         /*===============
//             BROADCAST
//         ===============*/

//         vm.startBroadcast();

//         // grant turnkey CALL permission on Account
//         bytes memory addTurnkeyCallPermissionData =
//             abi.encodeWithSelector(IPermissions.addPermission.selector, Operations.CALL, turnkey);
//         // initialize ERC721Account with initData
//         bytes memory accountInitData =
//             abi.encodeWithSelector(IERC721AccountRails.initialize.selector, addTurnkeyCallPermissionData);
//         bytes memory initData =
//             abi.encodeWithSelector(IERC6551AccountInitializer.initializeAccount.selector, accountImpl, accountInitData);
//         IERC6551Registry(erc6551Registry).createAccount(
//             accountGroupProxy, tokenChainId, tokenAddress, tokenId, counter, initData
//         );

//         vm.stopBroadcast();
//     }
// }

// interface IERC6551Registry {
//     /**
//      * @dev The registry SHALL emit the AccountCreated event upon successful account creation
//      */
//     event AccountCreated(
//         address account,
//         address indexed implementation,
//         uint256 chainId,
//         address indexed tokenContract,
//         uint256 indexed tokenId,
//         uint256 salt
//     );

//     /**
//      * @dev Creates a token bound account for a non-fungible token
//      *
//      * If account has already been created, returns the account address without calling create2
//      *
//      * If initData is not empty and account has not yet been created, calls account with
//      * provided initData after creation
//      *
//      * Emits AccountCreated event
//      *
//      * @return the address of the account
//      */
//     function createAccount(
//         address implementation,
//         uint256 chainId,
//         address tokenContract,
//         uint256 tokenId,
//         uint256 seed,
//         bytes calldata initData
//     ) external returns (address);

//     /**
//      * @dev Returns the computed token bound account address for a non-fungible token
//      *
//      * @return The computed address of the token bound account
//      */
//     function account(address implementation, uint256 chainId, address tokenContract, uint256 tokenId, uint256 salt)
//         external
//         view
//         returns (address);
// }
