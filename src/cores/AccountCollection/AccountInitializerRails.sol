// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC1967Upgrade} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Upgrade.sol";
import {IAccountInitializer} from "./interface/IAccountInitializer.sol";
import {AccountCollectionLib} from "./AccountCollectionLib.sol";
import {IGuards} from "../../guard/interface/IGuards.sol";
import {Operations} from "../../lib/Operations.sol";
// import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";

// Account initializer designed for use with AccountCollectionRails 
contract AccountInitializerRails is IAccountInitializer, ERC1967Upgrade {
    // delegatecalled by Account 1167Proxy
    function initializeAccount(address accountImpl, bytes memory initData) external {
        address accountCollection = AccountCollectionLib.accountCollection();
        // check collection guard before
        (address guard, bytes memory checkBeforeData) = IGuards(accountCollection).checkGuardBefore(
            Operations.INITIALIZE_ACCOUNT,
            abi.encode(msg.sender, accountImpl) // @todo: add chainId, tokenContract, tokenId
        );
        // save accountImpl to 1967 slot and initialize account
        ERC1967Upgrade._upgradeToAndCall(accountImpl, initData, false);
        // check collection guard after
        IGuards(accountCollection).checkGuardAfter(guard, checkBeforeData, "");
        // emit
        emit AccountInitialized(accountImpl);
    }
}
