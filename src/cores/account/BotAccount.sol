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
/// created by addresses with the `Operations::CALL_PERMIT` permission.
/// ERC1271 and ERC4337 compliance in combination with the 0xRails permissions system
/// provides convenient and modular private key management on an infrastructural level
contract BotAccount is Account, Ownable, Initializable {

    /*==================
        BOT ACCOUNT
    ==================*/

    /// @param _entryPointAddress The contract address for this chain's ERC-4337 EntryPoint contract
    constructor(address _entryPointAddress) Account(_entryPointAddress) Initializable() {}

    /// @param _owner The owner address of this contract which retains call permissions management rights
    /// @param _callPermitValidator The initial CallPermitValidator address to handle modular sig verification
    /// @param _trustedCallers The initial trusted caller addresses to support as recognized signers
    /// @notice Permission to execute `Call::call()` on this contract is granted to the EntryPoint in Accounts
    function initialize(
        address _owner, 
        address _callPermitValidator,
        address[] memory _trustedCallers
    ) external initializer {
        _addValidator(_callPermitValidator);
        _transferOwnership(_owner);

        // permit trusted callers to create valid `UserOp.signature`s via `CALL_PERMIT` permission only
        unchecked {
            for (uint256 i; i < _trustedCallers.length; ++i) {
                _addPermission(Operations.CALL_PERMIT, _trustedCallers[i]);
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

    /// @dev Support for legacy signatures is enabled by default only for the owner
    function _verifySigner(address _signer) internal view override returns (bool _validSigner) {
        if (_signer == owner()) return true;
    }

    // changes to core functionality must be restricted to owners to protect admins overthrowing
    function _checkCanUpdateExtensions() internal view override {
        _checkOwner();
    }

    function _authorizeUpgrade(address) internal view override {
        _checkOwner();
    }
}