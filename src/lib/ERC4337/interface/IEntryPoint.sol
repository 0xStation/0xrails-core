// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IStakeManager} from "src/lib/ERC4337/interface/IStakeManager.sol";
import {UserOperation} from "src/lib/ERC4337/utils/UserOperation.sol";

/// @title ERC-4337 IEntryPoint Interface
/// @author Original EIP-4337 Spec Authors: https://eips.ethereum.org/EIPS/eip-4337

/// @dev Interface contract taken from the EIP-4337 spec,
/// used to interface with each chain's ERC-4337 singleton EntryPoint contract
interface IEntryPoint is IStakeManager {
    function handleOps(UserOperation[] calldata ops, address payable beneficiary) external;

    function handleAggregatedOps(
        UserOpsPerAggregator[] calldata opsPerAggregator,
        address payable beneficiary
    ) external;

    function simulateValidation(UserOperation calldata userOp) external;

    function getNonce(address sender, uint192 key) external view returns (uint256 nonce);
        
    struct UserOpsPerAggregator {
        UserOperation[] userOps;
        IAggregator aggregator;
        bytes signature;
    }

    error ValidationResult(ReturnInfo returnInfo,
        StakeInfo senderInfo, StakeInfo factoryInfo, StakeInfo paymasterInfo);

    error ValidationResultWithAggregation(ReturnInfo returnInfo,
        StakeInfo senderInfo, StakeInfo factoryInfo, StakeInfo paymasterInfo,
        AggregatorStakeInfo aggregatorInfo);

    struct ReturnInfo {
        uint256 preOpGas;
        uint256 prefund;
        bool sigFailed;
        uint48 validAfter;
        uint48 validUntil;
        bytes paymasterContext;
    }

    struct StakeInfo {
        uint256 stake;
        uint256 unstakeDelaySec;
    }

    struct AggregatorStakeInfo {
        address actualAggregator;
        StakeInfo stakeInfo;
    }
}

/// @notice GroupOS does not make use of BLS aggregated signatures
/// This interface is required only for compiling the spec
/// @todo Look into the benefits and drawbacks (if any) of supporting aggregated signatures
interface IAggregator {

    function validateUserOpSignature(UserOperation calldata userOp)
        external view returns (bytes memory sigForUserOp);

  function aggregateSignatures(UserOperation[] calldata userOps) external view returns (bytes memory aggregatesSignature);

  function validateSignatures(UserOperation[] calldata userOps, bytes calldata signature) view external;
}
