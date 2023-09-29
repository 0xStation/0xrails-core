// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {UserOperation} from "src/lib/ERC4337/utils/UserOperation.sol";

/// @title ERC-4337 IOffchainPreparation Interface
/// @author Original EIP-4337 Spec Authors: https://eips.ethereum.org/EIPS/eip-4337

/// @dev Interface contract taken from the EntryPoint deployed to 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
/// used to interface with each chain's ERC-4337 singleton EntryPoint contract
/// @dev these interfaces are not a part of the formal EIP, but practically needed for offchain UserOp preparation
interface IUserOpPreparation {
    // called via staticCall, expects a revert of SenderAddressResult(address) to parse out senderAddress
    function getSenderAddress(bytes calldata initCode) external;
    // called via staticCall, expects simple return of userOpHash
    function getUserOpHash(UserOperation calldata userOp) external view returns (bytes32 userOpHash);
} 