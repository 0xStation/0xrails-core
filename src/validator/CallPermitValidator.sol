// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Validator} from "src/validator/Validator.sol";
import {UserOperation} from "src/lib/ERC4337/utils/UserOperation.sol";
import {Operations} from "src/lib/Operations.sol";
import {Access} from "src/access/Access.sol";
import {SignatureChecker} from "openzeppelin-contracts/utils/cryptography/SignatureChecker.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";

/// @dev Validator module that restricts valid signatures to only come from addresses
/// that have been granted the `CALL_PERMIT` permission in the calling Accounts contract 
contract CallPermitValidator is Validator {

    constructor(address _entryPointAddress) Validator(_entryPointAddress) {}

    /// @dev This example contract would be forwarded regular ECDSA signatures
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

        // terminate if recovered signer address does not match `userOp.sender`
        if (!SignatureChecker.isValidSignatureNow(userOp.sender, userOpHash, userOp.signature)) return SIG_VALIDATION_FAILED;
        
        // apply this validator's authentication logic
        bool validSigner = _verifySigner(userOp.sender);
        validationData = validSigner ? successData : SIG_VALIDATION_FAILED;
    }

    /// @dev This example contract would be forwarded regular ECDSA signatures
    function isValidSignature(bytes32 msgHash, bytes memory signature) 
        external view virtual returns (bytes4 magicValue) 
    {
        // recover signer address, reverting malleable or invalid signatures
        (address signer, ECDSA.RecoverError err) = ECDSA.tryRecover(msgHash, signature);
        // return if signature is malformed
        if (err != ECDSA.RecoverError.NoError) return INVALID_SIGNER;

        // apply this validator's authentication logic
        bool validSigner = _verifySigner(signer);
        magicValue = validSigner ? this.isValidSignature.selector : INVALID_SIGNER;
    }

    /// @dev This implementation is designed to authenticate addresses with `CALL_PERMIT` permissions
    /// or higher in the calling Account contract.
    function _verifySigner(address _signer) 
        internal view override returns (bool)
    {
        // check for `CALL_PERMIT` or superior permission
        return Access(msg.sender).hasPermission(Operations.CALL_PERMIT, _signer);
    }
}