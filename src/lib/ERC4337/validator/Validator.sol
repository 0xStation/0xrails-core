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

    /// @dev The EIP-712 type hash of UserOperation struct, used to derive domain separator
    bytes32 internal constant USEROPERATION_TYPE_HASH = 
        keccak256(
            "UserOperation("
                "address sender,"
                "uint256 nonce,"
                "bytes initCode,"
                "bytes callData,"
                "uint256 callGasLimit,"
                "uint256 verificationGasLimit,"
                "uint256 preVerificationGas,"
                "uint256 maxFeePerGas,"
                "uint256 maxPriorityFeePerGas,"
                "bytes paymasterAndData"
            ")"
        );

    /// @dev The EIP-712 domain type hash, required to derive domain separator
    bytes32 internal constant DOMAIN_TYPE_HASH =
        keccak256(
            "EIP712Domain("
                "string name,"
                "string version,"
                "uint256 chainId,"
                "address verifyingContract,"
                "address entryPoint"
            ")"
        );

    /// @dev The EIP-712 domain name, required to derive domain separator
    bytes32 internal constant NAME_HASH = keccak256("GroupOS");

    /// @dev The EIP-712 domain version, required to derive domain separator
    bytes32 internal constant VERSION_HASH = keccak256("0.0.1");

    /// @dev The EIP-712 domain separator, computed in the constructor using the current chain id,
    /// Validator module's own address, and EntryPoint address to prevent replay attacks across networks
    bytes32 public immutable INITIAL_DOMAIN_SEPARATOR;

    address public immutable entryPoint;

    constructor(address _entryPointAddress) {
        entryPoint = _entryPointAddress;
        INITIAL_DOMAIN_SEPARATOR = _domainSeparator();
    }

    /*===============
        INTERNALS
    ===============*/

    /// @dev Function to compute hash of an ERC4337 UserOperation
    /// @param userOp The UserOperation struct to be hashed
    function _hashUserOp(UserOperation memory userOp) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                USEROPERATION_TYPE_HASH,
                userOp.sender,
                userOp.nonce,
                keccak256(userOp.initCode),
                keccak256(userOp.callData),
                userOp.callGasLimit,
                userOp.verificationGasLimit,
                userOp.preVerificationGas,
                userOp.maxFeePerGas,
                userOp.maxPriorityFeePerGas,
                keccak256(userOp.paymasterAndData)
            )
        );
    }

    /// @dev Function to compute DOMAIN_SEPARATOR at construction, 
    /// @dev Per ERC-4337 recommendation, includes EntryPoint address
    function _domainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                DOMAIN_TYPE_HASH, NAME_HASH, VERSION_HASH, block.chainid, address(this), entryPoint
            )
        );
    }
}