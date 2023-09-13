// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {UserOperation} from "src/lib/ERC4337/utils/UserOperation.sol";

interface IValidator {

    function validateUserOp(
        UserOperation calldata userOp, 
        bytes32 userOpHash, 
        uint256 missingAccountFunds
    ) external returns (uint256 validationData);

    function isValidSignature(bytes32 userOpHash, bytes calldata signature) 
        external view returns (bytes4);
}