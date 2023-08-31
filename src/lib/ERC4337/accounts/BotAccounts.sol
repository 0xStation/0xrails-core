// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Accounts} from "src/lib/ERC4337/accounts/Accounts.sol";
import {IEntryPoint} from "src/lib/ERC4337/interface/IEntryPoint.sol";
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

    /// @param _entryPointAddress The contract address for this chain's ERC-4337 EntryPoint contract
    /// @param _owner The owner address of this contract which retains Turnkey management rights
    /// @param _turnkeys The initial turnkey addresses to support as recognized signers
    /// @notice Permission to call `execute()` on this contract is granted to the EntryPoint in Accounts
    constructor(
        address _entryPointAddress, 
        address _owner, 
        address[] memory _turnkeys
    ) Accounts(_entryPointAddress) {
        _transferOwnership(_owner);

        // permit Turnkeys to call `execute()` on this contract via valid UserOp.signature only
        unchecked {
            for (uint256 i; i < _turnkeys.length; ++i) {
                _addPermission(Operations.CALL_PERMIT, _turnkeys[i]);
            }
        }
    }

    /// @dev Function to pre-fund the EntryPoint contract's `depositTo()` function
    /// using payable call context + this contract's native currency balance
    function preFundEntryPoint() public payable override {
        uint256 totalFunds = msg.value + address(this).balance;
        IEntryPoint(entryPoint()).depositTo{ value : totalFunds }(address(this));
    }

    /// @dev Function to withdraw funds using the EntryPoint's `withdrawTo()` function
    /// @param recipient The address to receive from the EntryPoint balance
    /// @param amount The amount of funds to withdraw from the EntryPoint
    function withdrawFromEntryPoint(address payable recipient, uint256 amount) public override onlyOwner {
        IEntryPoint(entryPoint()).withdrawTo(recipient, amount);
    }

    /*===========
        VIEWS
    ===========*/

    /// @dev Function to view the EntryPoint's deposit balance for this BotAccount contract address
    function getEntryPointBalance() public view returns (uint256) {
        return IEntryPoint(entryPoint()).balanceOf(address(this));
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