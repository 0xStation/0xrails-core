// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Validator} from "src/lib/ERC4337/validator/Validator.sol";
import {UserOperation} from "src/lib/ERC4337/utils/UserOperation.sol";
import {Operations} from "src/lib/Operations.sol";
import {Access} from "src/access/Access.sol";
import {SignatureChecker} from "openzeppelin-contracts/utils/cryptography/SignatureChecker.sol";

/// @dev Validator module that restricts valid signatures to only come from recognized Turnkeys
/// for the calling Accounts contract 
contract TurnkeyValidator is Validator {

    constructor(address _entryPointAddress) Validator(_entryPointAddress) {}

    /// @dev This example contract would only be forwarded signatures formatted as follows:
    /// `abi.encodePacked(address signer, bytes memory eoaSig)`
    function validateUserOp(
        UserOperation calldata userOp, 
        bytes32 userOpHash, 
        uint256 missingAccountFunds
    ) external virtual returns (uint256 validationData) {
        // silence compiler by discarding unused variable
        (missingAccountFunds);

        // deconstruct signature into `(validator, nestedSignature)`
        (address signer, bytes memory nestedSignature) = abi.decode(userOp.signature, (address, bytes));

        bool validSig = _verifySignature(signer, userOpHash, nestedSignature);
        validationData = validSig ? 0 : SIG_VALIDATION_FAILED;
    }

    function isValidSignature(bytes32 userOpHash, bytes calldata signature) 
        external view virtual returns (bytes4 magicValue) 
    {
        (address signer, bytes memory nestedSignature) = abi.decode(signature, (address, bytes));

        bool validSig = _verifySignature(signer, userOpHash, nestedSignature);
        magicValue = validSig ? this.isValidSignature.selector : INVALID_SIGNER; 
    }

    /// @dev This implementation is designed to validate addresses granted `CALL_PERMIT` permissions
    /// or higher in the calling Account contract. It expects EIP-712 typed signatures.
    function _verifySignature(address signer, bytes32 userOpHash, bytes memory nestedSignature) 
        internal view override returns (bool)
    {
        if (!SignatureChecker.isValidSignatureNow(signer, userOpHash, nestedSignature)) return false;

        // check for turnkey or superior permission
        return Access(msg.sender).hasPermission(Operations.CALL_PERMIT, signer);
    }
}