// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {UserOperation} from "src/lib/ERC4337/utils/UserOperation.sol";

/// @title ERC-4337 IAccount Interface
/// @author Original EIP-4337 Spec Authors: https://eips.ethereum.org/EIPS/eip-4337

/// @dev Interface contract taken from the original EIP-4337 spec,
/// used to signify ERC-4337 compliance for smart account wallets inheriting from this contract
interface IAccount {

    function validateUserOp(
        UserOperation calldata userOp, 
        bytes32 userOpHash, 
        uint256 missingAccountFunds
    )  external returns (uint256 validationData);
}
