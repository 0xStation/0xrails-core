// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {UserOperation} from "src/lib/ERC4337/utils/UserOperation.sol";

/// @title ERC-4337 IPaymaster Interface
/// @author Original EIP-4337 Spec Authors: https://eips.ethereum.org/EIPS/eip-4337

/// @dev Interface contract taken from the EIP-4337 spec,
/// used to define requirements of a ERC-4337 Paymaster contract
interface IPaymaster {
    function validatePaymasterUserOp(
        UserOperation calldata userOp, 
        bytes32 userOpHash, 
        uint256 maxCost
    ) external returns (bytes memory context, uint256 validationData);

    function postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) external;

    enum PostOpMode {
        opSucceeded, // user op succeeded
        opReverted, // user op reverted. still has to pay for gas.
        postOpReverted // user op succeeded, but caused postOp to revert
    }
}