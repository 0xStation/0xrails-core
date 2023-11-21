// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Validator} from "src/validator/Validator.sol";
import {UserOperationStruct} from "src/lib/ERC4337/utils/UserOperation.sol";
import {Ownable} from "src/access/ownable/Ownable.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {SignatureChecker} from "openzeppelin-contracts/utils/cryptography/SignatureChecker.sol";

/// @dev Example Validator module that restricts valid signatures to only come from the owner
/// of the calling Accounts contract
contract OnlyOwnerValidator is Validator {
    constructor(address _entryPointAddress) Validator(_entryPointAddress) {}

    /// @dev Function to enable user operations and comply with `IAccount` interface defined in the EIP-4337 spec
    /// @dev This contract expects signatures in this function's call context to contain a `signer` address
    /// prepended to the ECDSA `nestedSignature`, ie: `abi.encodePacked(address signer, bytes memory nestedSig)`
    /// @param userOp The ERC-4337 user operation, including a `signature` to be recovered and verified
    /// @param userOpHash The hash of the user operation that was signed
    /// @notice The top level call context to an `Account` implementation must prepend
    /// an additional 32-byte word packed with the `VALIDATOR_FLAG` and this address
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 /*missingAccountFunds*/ )
        external
        virtual
        returns (uint256 validationData)
    {
        bytes memory signerData = userOp.signature[:20];
        address signer = address((bytes20(signerData)));

        bytes memory nestedSig = userOp.signature[20:];

        // terminate if recovered signer address does not match packed signer
        if (!SignatureChecker.isValidSignatureNow(signer, userOpHash, nestedSig)) return SIG_VALIDATION_FAILED;

        // apply this validator's authentication logic
        bool validSigner = signer == Ownable(msg.sender).owner();
        validationData = validSigner ? 0 : SIG_VALIDATION_FAILED;
    }

    /// @dev Function to enable smart contract signature verification and comply with the EIP-1271 spec
    /// @dev This example contract expects signatures in this function's call context
    /// to contain a `signer` address prepended to the ECDSA `nestedSignature`
    /// @param msgHash The hash of the message signed
    /// @param signature The signature to be recovered and verified
    /// @notice The top level call context to an `Account` implementation must prepend
    /// an additional 32-byte word packed with the `VALIDATOR_FLAG` and this address
    function isValidSignature(bytes32 msgHash, bytes memory signature)
        external
        view
        virtual
        returns (bytes4 magicValue)
    {
        bytes32 signerData;
        assembly {
            signerData := mload(add(signature, 0x20))
        }
        address signer = address(bytes20(signerData));

        // start is now 20th index since only signer is prepended
        uint256 start = 20;
        uint256 len = signature.length - start;
        bytes memory nestedSig = new bytes(len);
        for (uint256 i; i < len; ++i) {
            nestedSig[i] = signature[start + i];
        }

        // use SignatureChecker to evaluate `signer` and `nestedSig`
        bool validSig = SignatureChecker.isValidSignatureNow(signer, msgHash, nestedSig);

        // apply this validator's authentication logic
        if (validSig && signer == Ownable(msg.sender).owner()) {
            magicValue = this.isValidSignature.selector;
        } else {
            magicValue = INVALID_SIGNER;
        }
    }
}
