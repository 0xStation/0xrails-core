// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Accounts} from "src/lib/accounts/Accounts.sol";
import {Ownable} from "src/access/ownable/Ownable.sol";
import {OwnableInternal} from "src/access/ownable/OwnableInternal.sol";
import {Access} from "src/access/Access.sol";
import {Operations} from "src/lib/Operations.sol";

/// @title Station Network Bot Accounts Contract
/// @author 👦🏻👦🏻.eth

/// @dev This contract provides a single hub for managing and verifying signatures
/// created by addresses with private keys generated via Turnkey's API, abstracting them away.
/// ERC1271-compliance in combination with enabling and disabling individual Turnkey addresses 
/// provides convenient and modular private key management on an infrastructural level
contract BotAccounts is Accounts, Ownable {

    /*==================
        BOT ACCOUNTS
    ==================*/

    /// @param _owner The owner address of this contract which retains Turnkey management rights
    /// @param _turnkeys The initial turnkey addresses to support as recognized signers
    constructor(address _owner, address[] memory _turnkeys) {
        _transferOwnership(_owner);

        unchecked {
            for (uint256 i; i < _turnkeys.length; ++i) {
                _addPermission(Operations.EXECUTE_PERMIT, _turnkeys[i]);
            }
        }
    }

    /// @notice This function must be overridden by contracts inheriting `Account` to delineate 
    /// the type of Account: `Bot`, `Member`, or `Group`
    /// @dev Owner stored explicitly using OwnableStorage's ERC7201 namespace
    function owner() public view virtual override(Access, OwnableInternal) returns (address) {
        return OwnableInternal.owner();
    }

    // changes to core functionality must be restricted to owners to protect admins overthrowing
    function _checkCanUpdateExtensions() internal view override {
        _checkOwner();
    }

    function _authorizeUpgrade(address) internal view override {
        _checkOwner();
    }
}