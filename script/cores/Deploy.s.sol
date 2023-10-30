// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ScriptUtils} from "lib/protocol-ops/script/ScriptUtils.sol";
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

        bytes32 salt = ScriptUtils.create2Salt;
        string memory saltString = Strings.toHexString(uint256(salt), 32);
        
        membershipImpl = new ERC721Rails{salt: salt}();
        pointsImpl = new ERC20Rails{salt: salt}();
        badgeImpl = new ERC1155Rails{salt: salt}();

        logAddress("ERC721RailsImpl @", Strings.toHexString(address(membershipImpl)));
        logAddress("ERC20RailsImpl @", Strings.toHexString(address(pointsImpl)));
        logAddress("ERC1155RailsImpl @", Strings.toHexString(address(badgeImpl)));
        vm.stopBroadcast();
    }
}