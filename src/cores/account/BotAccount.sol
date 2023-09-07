// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Account} from "src/cores/account/Account.sol";
import {IEntryPoint} from "src/lib/ERC4337/interface/IEntryPoint.sol";
import {ValidatorsStorage} from "src/validator/ValidatorsStorage.sol";
import {Initializable} from "src/lib/initializable/Initializable.sol";
import {Ownable} from "src/access/ownable/Ownable.sol";
import {OwnableInternal} from "src/access/ownable/OwnableInternal.sol";
import {Access} from "src/access/Access.sol";
import {Operations} from "src/lib/Operations.sol";

/// @title Station Network Bot Account Contract
/// @author 👦🏻👦🏻.eth

/// @dev This contract provides a single hub for managing and verifying signatures
/// created by addresses with private keys generated via Turnkey's API, abstracting them away.
/// ERC1271-compliance in combination with enabling and disabling individual Turnkey addresses 
/// provides convenient and modular private key management on an infrastructural level
contract BotAccount is Account, Ownable, Initializable {

    /*==================
        BOT ACCOUNT
    ==================*/

    /// @param _entryPointAddress The contract address for this chain's ERC-4337 EntryPoint contract
    constructor(address _entryPointAddress) Account(_entryPointAddress) {}

    /// @param _owner The owner address of this contract which retains Turnkey management rights
    /// @param _turnkeyValidator The initial TurnkeyValidator address to handle modular sig verification
    /// @param _turnkeys The initial turnkey addresses to support as recognized signers
    /// @notice Permission to execute `Call::call()` on this contract is granted to the EntryPoint in Accounts
    function initialize(
        address _owner, 
        address _turnkeyValidator,
        address[] memory _turnkeys
    ) external initializer {
        _addValidator(_turnkeyValidator);
        _transferOwnership(_owner);

        // permit Turnkeys to create valid `UserOp.signature`s via `CALL_PERMIT` permission only
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
        IEntryPoint(entryPoint).depositTo{ value : totalFunds }(address(this));
    }

    /// @dev Function to withdraw funds using the EntryPoint's `withdrawTo()` function
    /// @param recipient The address to receive from the EntryPoint balance
    /// @param amount The amount of funds to withdraw from the EntryPoint
    function withdrawFromEntryPoint(address payable recipient, uint256 amount) public override onlyOwner {
        IEntryPoint(entryPoint).withdrawTo(recipient, amount);
    }

    /*===========
        VIEWS
    ===========*/

    /// @dev Function to view the EntryPoint's deposit balance for this BotAccount contract address
    function getEntryPointBalance() public view returns (uint256) {
        return IEntryPoint(entryPoint).balanceOf(address(this));
    }

    /// @notice This function must be overridden by contracts inheriting `Account` to delineate 
    /// the type of Account: `Bot`, `Member`, or `Group`
    /// @dev Owner stored explicitly using OwnableStorage's ERC7201 namespace
    function owner() public view virtual override(Access, OwnableInternal) returns (address) {
        return OwnableInternal.owner();
    }

    /*===============
        OVERRIDES
    ===============*/

    /// @dev Function to add the address of a Validator module to storage
    function addValidator(address validator) public override onlyOwner {
        _addValidator(validator);
    }

    /// @dev Function to remove the address of a Validator module to storage
    function removeValidator(address validator) public override onlyOwner {
        _removeValidator(validator);
    }

    /*===============
        INTERNALS
    ===============*/

    function _addValidator(address validator) internal {
        ValidatorsStorage.Layout storage layout = ValidatorsStorage.layout();
        layout._validators[validator] = true;
    }

    function _removeValidator(address validator) internal {
        ValidatorsStorage.Layout storage layout = ValidatorsStorage.layout();
        layout._validators[validator] = false;
    }

    // changes to core functionality must be restricted to owners to protect admins overthrowing
    function _checkCanUpdateExtensions() internal view override {
        _checkOwner();
    }

    function _authorizeUpgrade(address) internal view override {
        _checkOwner();
    }
}