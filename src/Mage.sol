// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Access} from "./access/Access.sol";
import {GuardRouter} from "./guard/GuardRouter.sol";
import {ExtensionRouter} from "./extension/ExtensionRouter.sol";
import {Execute} from "./lib/Execute.sol";
import {Multicall} from "lib/openzeppelin-contracts/contracts/utils/Multicall.sol";

/**
 * A Solidity framework for creating complex and evolving onchain structures.
 * Mage is an acronym for the architecture pattern's four layers: Module, Access, Guard, and Extension.
 * All Mage-inherited contracts receive a batteries-included contract development kit.
 */
contract Mage is Access, GuardRouter, ExtensionRouter, Execute, Multicall {
    function contractURI() public view virtual returns (string memory uri) {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(Access, GuardRouter, ExtensionRouter)
        returns (bool)
    {
        return Access.supportsInterface(interfaceId) || GuardRouter.supportsInterface(interfaceId)
            || ExtensionRouter.supportsInterface(interfaceId);
    }

    function _checkCanUpdateExtensions() internal view override {
        _checkSenderIsAdmin();
    }

    function _checkCanUpdateGuards() internal view override {
        _checkSenderIsAdmin();
    }

    function _checkCanUpdatePermissions() internal view override {
        _checkSenderIsAdmin();
    }

    function _checkCanExecute() internal view override {
        _checkSenderIsAdmin();
    }
}
