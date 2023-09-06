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
    /// `abi.encode(address signer, bytes memory eoaSig)` (abi decoding fails for `abi.encodePacked`)
    function validateUserOp(
        UserOperation calldata userOp, 
        bytes32 userOpHash, 
        uint256 missingAccountFunds
    ) external virtual returns (uint256 validationData) {
        // silence compiler by discarding unused variable
        (missingAccountFunds);

        // deconstruct signature into `(validator, nestedSignature)`
        (address signer, bytes memory nestedSignature) = abi.decode(userOp.signature, (address, bytes));
        uint256 invalidSig = 1;

        bool validSig = _verifySignature(signer, userOpHash, nestedSignature);
        validationData = validSig ? 0 : invalidSig;
    }

    function isValidSignature(bytes32 userOpHash, bytes calldata signature) 
        external view virtual returns (bytes4 magicValue) 
    {
        (address signer, bytes memory nestedSignature) = abi.decode(signature, (address, bytes));
        bytes4 invalidSig = hex'ffffffff';

        bool validSig = _verifySignature(signer, userOpHash, nestedSignature);
        magicValue = validSig ? this.isValidSignature.selector : invalidSig;
    }

    function _verifySignature(address signer, bytes32 userOpHash, bytes memory nestedSignature) 
        internal view override returns (bool) 
    {
        if (!SignatureChecker.isValidSignatureNow(signer, userOpHash, nestedSignature)) return false;
        return signer == Ownable(msg.sender).owner();
    }
}