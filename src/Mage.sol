// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Access} from "./access/Access.sol";
import {Guards} from "./guard/Guards.sol";
import {Extensions} from "./extension/Extensions.sol";
import {Execute} from "./lib/Execute.sol";
import {Multicall} from "openzeppelin-contracts/utils/Multicall.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts/proxy/utils/UUPSUpgradeable.sol";

/**
 * A Solidity framework for creating complex and evolving onchain structures.
 * Mage is an acronym for the architecture pattern's four layers: Module, Access, Guard, and Extension.
 * All Mage-inherited contracts receive a batteries-included contract development kit.
 */
contract Mage is Access, Guards, Extensions, Execute, Multicall, UUPSUpgradeable {
    function contractURI() public view virtual returns (string memory uri) {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(Access, Guards, Extensions)
        returns (bool)
    {
        return Access.supportsInterface(interfaceId) || Guards.supportsInterface(interfaceId)
            || Extensions.supportsInterface(interfaceId);
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

    function _authorizeUpgrade(address) internal view override {
        _checkSenderIsAdmin();
    }
}
