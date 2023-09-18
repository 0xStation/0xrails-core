// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Validator} from "src/validator/Validator.sol";
import {UserOperation} from "src/lib/ERC4337/utils/UserOperation.sol";
import {Ownable} from "src/access/ownable/Ownable.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {SignatureChecker} from "openzeppelin-contracts/utils/cryptography/SignatureChecker.sol";

/// @dev Example Validator module that restricts valid signatures to only come from the owner
/// of the calling Accounts contract
contract OnlyOwnerValidator is Validator {
    constructor(address _entryPointAddress) Validator(_entryPointAddress) {}

    /// @dev This example contract would only be forwarded signatures formatted as follows:
    /// `abi.encodePacked(address signer, bytes memory eoaSig)`
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
