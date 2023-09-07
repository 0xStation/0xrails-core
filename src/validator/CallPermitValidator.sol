// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Validator} from "src/validator/Validator.sol";
import {UserOperation} from "src/lib/ERC4337/utils/UserOperation.sol";
import {Operations} from "src/lib/Operations.sol";
import {Access} from "src/access/Access.sol";
import {SignatureChecker} from "openzeppelin-contracts/utils/cryptography/SignatureChecker.sol";

/// @dev Validator module that restricts valid signatures to only come from recognized Turnkeys
/// for the calling Accounts contract 
contract CallPermitValidator is Validator {

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

        /// @notice BLS sig aggregator and timestamp expiry are not currently supported by this contract 
        /// so `bytes20(0x0)` and `bytes6(0x0)` suffice. To enable support for aggregator and timestamp expiry,
        /// override the following params
        bytes20 authorizer;
        bytes6 validUntil;
        bytes6 validAfter;
        uint256 successData = uint256(bytes32(abi.encodePacked(authorizer, validUntil, validAfter)));

        // deconstruct signature into `(validator, nestedSignature)`
        (address signer, bytes memory nestedSignature) = abi.decode(userOp.signature, (address, bytes));

        bool validSig = _verifySignature(signer, userOpHash, nestedSignature);
        validationData = validSig ? successData : SIG_VALIDATION_FAILED;
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

        // check for `CALL_PERMIT` or superior permission
        return Access(msg.sender).hasPermission(Operations.CALL_PERMIT, signer);
    }
}