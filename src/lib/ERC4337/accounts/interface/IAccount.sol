// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @title ERC-4337 IAccount Interface
/// @author Original EIP-4337 Spec Authors: https://eips.ethereum.org/EIPS/eip-4337

/// @dev Interface contract taken from the original EIP-4337 spec,
/// used to signify ERC-4337 compliance for smart account wallets inheriting from this contract
interface IAccount {

    struct UserOperation {
        address sender;
        uint256 nonce;
        bytes initCode;
        bytes callData;
        uint256 callGasLimit;
        uint256 verificationGasLimit;
        uint256 preVerificationGas;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        bytes paymasterAndData;
        bytes signature;
    }

    function validateUserOp(
        UserOperation calldata userOp, 
        bytes32 userOpHash, 
        uint256 missingAccountFunds
    )  external returns (uint256 validationData);
}
