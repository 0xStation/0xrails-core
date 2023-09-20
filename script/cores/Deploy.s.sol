// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ScriptUtils} from "script/utils/ScriptUtils.sol";
import {ERC721Rails} from "src/cores/ERC721/ERC721Rails.sol";
import {ERC20Rails} from "src/cores/ERC20/ERC20Rails.sol";
import {ERC1155Rails} from "src/cores/ERC1155/ERC1155Rails.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

/// @dev Script to deploy new implementations of BotAccount.sol and CallPermitValidator.sol only.
/// To deploy a factory enabling permissionless creation of proxy accounts, see BotAccountFactory.s.sol
contract Deploy is ScriptUtils {
    function run() public {
        /*=================
            ENVIRONMENT 
        =================*/

        /// @dev The following contracts will be deployed and initialized by this script
        ERC721Rails membershipImpl;
        ERC20Rails pointsImpl;
        ERC1155Rails badgeImpl;

        /*===============
            BROADCAST 
        ===============*/

        vm.startBroadcast();
        string memory saltString = ScriptUtils.readSalt("salt");
        bytes32 salt = bytes32(bytes(saltString));
        
        membershipImpl = new ERC721Rails{salt: salt}();
        pointsImpl = new ERC20Rails{salt: salt}();
        badgeImpl = new ERC1155Rails{salt: salt}();

        ScriptUtils.writeUsedSalt(saltString, string.concat("ERC721RailsImpl @", Strings.toHexString(address(membershipImpl))));
        ScriptUtils.writeUsedSalt(saltString, string.concat("ERC20RailsImpl @", Strings.toHexString(address(pointsImpl))));
        ScriptUtils.writeUsedSalt(saltString, string.concat("ERC1155RailsImpl @", Strings.toHexString(address(badgeImpl))));
        vm.stopBroadcast();
    }
}