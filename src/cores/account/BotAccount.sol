// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {AccountRails} from "src/cores/account/AccountRails.sol";
import {Account} from "src/cores/account/Account.sol";
import {IEntryPoint} from "src/lib/ERC4337/interface/IEntryPoint.sol";
import {UserOperationStruct} from "src/lib/ERC4337/utils/UserOperation.sol";
import {ValidatorsStorage} from "src/validator/ValidatorsStorage.sol";
import {Initializable} from "src/lib/initializable/Initializable.sol";
import {Ownable} from "src/access/ownable/Ownable.sol";
import {Ownable} from "src/access/ownable/Ownable.sol";
import {Access} from "src/access/Access.sol";
import {Operations} from "src/lib/Operations.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";

/// @title Station Network Bot Account Contract
/// @author 👦🏻👦🏻.eth

/// @dev This contract provides a single hub for managing and verifying signatures
/// created either using the GroupOS modular validation schema or default signatures.
/// ERC1271 and ERC4337 are supported, in combination with the 0xRails permissions system
contract BotAccount is AccountRails, Ownable, Initializable {
    /*==================
        BOT ACCOUNT
    ==================*/

    /// @param _entryPointAddress The contract address for this chain's ERC-4337 EntryPoint contract
    constructor(address _entryPointAddress) Account(_entryPointAddress) Initializable() {}

    /// @param _owner The owner address of this contract which retains call permissions management rights
    /// @param _callPermitValidator The initial CallPermitValidator address to handle modular sig verification
    /// @param _trustedCallers The initial trusted caller addresses to support as recognized signers
    /// @notice Permission to execute `Call::call()` on this contract is granted to the EntryPoint in Accounts
    function initialize(address _owner, address _callPermitValidator, address[] memory _trustedCallers)
        external
        initializer
    {
        _addValidator(_callPermitValidator);
        _transferOwnership(_owner);

        // permit trusted callers to create valid `UserOp.signature`s via `CALL_PERMIT` permission only
        unchecked {
            for (uint256 i; i < _trustedCallers.length; ++i) {
                _addPermission(Operations.CALL_PERMIT, _trustedCallers[i]);
            }
        }
    }

    /*===============
        OVERRIDES
    ===============*/

    /// @dev When evaluating signatures that don't contain the `VALIDATOR_FLAG`, authenticate only the owner
    function _defaultValidateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 /*missingAccountFunds*/ )
        internal
        view
        virtual
        override
        returns (bool)
    {
        // recover signer address and any error
        (address signer, ECDSA.RecoverError err) = ECDSA.tryRecover(userOpHash, userOp.signature);
        // return if signature is malformed
        if (err != ECDSA.RecoverError.NoError) return false;
        // return if signer is not owner
        if (signer != owner()) return false;

        return true;
    }

    /// @dev When evaluating signatures that don't contain the `VALIDATOR_FLAG`, authenticate only the owner
    function _defaultIsValidSignature(bytes32 hash, bytes memory signature)
        internal
        view
        virtual
        override
        returns (bool)
    {
        // support non-modular signatures by recovering signer address and reverting malleable or invalid signatures
        (address signer, ECDSA.RecoverError err) = ECDSA.tryRecover(hash, signature);
        // return if signature is malformed
        if (err != ECDSA.RecoverError.NoError) return false;
        // return if signer is not owner
        if (signer != owner()) return false;

        return true;
    }

    /// @notice This function must be overridden by contracts inheriting `Account` to delineate
    /// the type of Account: `Bot`, `Member`, or `Group`
    /// @dev Owner stored explicitly using OwnableStorage's ERC7201 namespace
    function owner() public view virtual override(Access, Ownable) returns (address) {
        return Ownable.owner();
    }

    /// @dev Function to withdraw funds using the EntryPoint's `withdrawTo()` function
    /// @param recipient The address to receive from the EntryPoint balance
    /// @param amount The amount of funds to withdraw from the EntryPoint
    function withdrawFromEntryPoint(address payable recipient, uint256 amount) public virtual override onlyOwner {
        IEntryPoint(entryPoint).withdrawTo(recipient, amount);
    }

    // changes to core functionality must be restricted to owners to protect admins overthrowing
    function _checkCanUpdateExtensions() internal view override {
        _checkOwner();
    }

    function _authorizeUpgrade(address) internal view override {
        _checkOwner();
    }
}
