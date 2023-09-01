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
                "address verifyingContract"
            ")"
        );

    /// @dev The EIP-712 domain name, required to derive domain separator
    bytes32 internal constant NAME_HASH = keccak256("GroupOS");

    /// @dev The EIP-712 domain version, required to derive domain separator
    bytes32 internal constant VERSION_HASH = keccak256("0.0.1");

    /// @dev The EIP-712 domain separator, computed in the constructor using the current chain id,
    /// Validator module's own address, and EntryPoint address to prevent replay attacks across networks
    bytes32 public immutable INITIAL_DOMAIN_SEPARATOR;

    /// @dev The chain id at construction time, to protect against forks
    uint256 public immutable INITIAL_CHAIN_ID;

    /// @dev Since the EntryPoint contract uses chainid and its own address to generate request ids, 
    /// its address on this chain must be available to all ERC4337-compliant validators.
    address public immutable entryPoint;

    constructor(address _entryPointAddress) {
        INITIAL_DOMAIN_SEPARATOR = _domainSeparator();
        INITIAL_CHAIN_ID = block.chainid;
        entryPoint = _entryPointAddress; 
    }

    /*===============
        VALIDATOR
    ===============*/

    /// @dev Function to compute the hash of the full EIP-712 digest for this validator's domain
    /// since it is the verifying contract of the GroupOS schema
    /// @dev Signatures can also be created offchain.
    /// @notice OZ's ECDSA library prevents the zero address from being returned as a result
    /// of `recover()`, even when `ecrecover()` does as part of assessing an invalid signature
    /// For this reason, checks preventing a call to `hasPermission[address(0x0)]` are not necessary
    function getTypedDataHash(bytes32 userOpHash) public view returns (bytes32) {
        return ECDSA.toTypedDataHash(
            INITIAL_CHAIN_ID == block.chainid ? INITIAL_DOMAIN_SEPARATOR : _domainSeparator(), 
            userOpHash
        );
    }

    /// @dev Convenience function to generate an EntryPoint request id for a given UserOperation.
    /// Use this output to generate an un-typed digest for signing to comply with `eth_sign` + EIP-191 
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

    /// @dev Function to compute DOMAIN_SEPARATOR at construction, 
    function _domainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                DOMAIN_TYPE_HASH, NAME_HASH, VERSION_HASH, block.chainid, address(this)
            )
        );
    }
}