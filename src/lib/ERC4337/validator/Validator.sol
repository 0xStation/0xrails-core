// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IValidator} from "src/lib/ERC4337/validator/interface/IValidator.sol";
import {UserOperation} from "src/lib/ERC4337/utils/UserOperation.sol";
import {Ownable} from "src/access/ownable/Ownable.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";

abstract contract Validator is IValidator {

    /*=============
        STORAGE
    =============*/

    /// @dev Error code for invalid EIP-4337 `validateUserOp()`signature
    /// @dev Error return value is abbreviated to 1 since it need not include time range
    uint8 internal constant SIG_VALIDATION_FAILED = 1;
    /// @dev Error code for invalid EIP-1271 signature in `isValidSignature()`
    /// @dev Nonzero to define invalid sig error, as opposed to wrong validator address error, ie: `bytes4(0)`
    bytes4 internal constant INVALID_SIGNER = hex'ffffffff';

    /// @dev Since the EntryPoint contract uses chainid and its own address to generate request ids, 
    /// its address on this chain must be available to all ERC4337-compliant validators.
    address public immutable entryPoint;

    constructor(address _entryPointAddress) {
        entryPoint = _entryPointAddress; 
    }

    /*===============
        VALIDATOR
    ===============*/

    /// @dev Convenience function to generate an EntryPoint request id for a given UserOperation.
    /// Use this output to generate an un-typed digest for signing to comply with `eth_sign` + EIP-191 
    /// @param userOp The 4337 UserOperation to hash. The struct's signature member is discarded.
    /// @notice Can also be done offchain or called directly on the EntryPoint contract as it is identical
    function getUserOpHash(UserOperation calldata userOp) public view returns (bytes32) {
        return keccak256(abi.encode(_innerOpHash(userOp), address(entryPoint), block.chainid));
    }

    /*===============
        INTERNALS
    ===============*/

    /// @dev Function to verify signatures forwarded to this contract. Must be overridden by validator
    /// child contracts in a way that suits the use case of their design
    function _verifySignature(
        address signer, 
        bytes32 userOpHash, 
        bytes memory nestedSignature
    ) internal view virtual returns (bool);

    /// @dev Function to compute the struct hash, used within EntryPoint's `getUserOpHash()` function
    function _innerOpHash(UserOperation memory userOp) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                userOp.sender, userOp.nonce,
                keccak256(userOp.initCode), keccak256(userOp.callData),
                userOp.callGasLimit, userOp.verificationGasLimit, userOp.preVerificationGas,
                userOp.maxFeePerGas, userOp.maxPriorityFeePerGas,
                keccak256(userOp.paymasterAndData)
            )
        );
    }
}