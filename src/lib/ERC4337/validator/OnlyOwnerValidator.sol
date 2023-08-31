// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Validator} from "src/lib/ERC4337/validator/Validator.sol";
import {UserOperation} from "src/lib/ERC4337/utils/UserOperation.sol";
import {Ownable} from "src/access/ownable/Ownable.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";

/// @dev Example Validator module that restricts valid signatures to only come from the owner
/// of the calling Accounts contract 
contract OnlyOwnerValidator is Validator {

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
        (address signer, bytes memory nestedSignature) = abi.decode(userOp.signature, (address, bytes));

        require(signer == Ownable(msg.sender).owner());

        // generate EIP712 hash from `userOpHash`
        bytes32 digest = ECDSA.toTypedDataHash(_domainSeparator(), userOpHash);
    }

    function isValidSignature(bytes32 userOpHash, bytes calldata signature) 
        external view virtual returns (bytes4 magicValue) 
    {
        //todo
    }
}