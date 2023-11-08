// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ScriptUtils} from "protocol-ops/script/ScriptUtils.sol";
import {JsonManager} from "protocol-ops/script/lib/JsonManager.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC721AccountRails} from "src/cores/ERC721Account/ERC721AccountRails.sol";

contract ERC721AccountRailsScript is ScriptUtils {

    ERC721AccountRails erc721AccountRails;

    function run() public {

        vm.startBroadcast();

        bytes32 salt = ScriptUtils.create2Salt;

        erc721AccountRails = new ERC721AccountRails{salt: salt}(ScriptUtils.entryPointAddress);
        assert(erc721AccountRails.initialized() == true);

        vm.stopBroadcast();

        logAddress("ERC721AccountRails @", Strings.toHexString(address(erc721AccountRails)));
    }
}