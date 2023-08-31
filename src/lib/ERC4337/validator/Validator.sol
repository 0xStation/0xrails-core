// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IValidator} from "src/lib/ERC4337/validator/interface/IValidator.sol";
import {UserOperation} from "src/lib/ERC4337/utils/UserOperation.sol";

contract Validator is IValidator {

    function validateUserOp(
        UserOperation calldata userOp, 
        bytes32 userOpHash, 
        uint256 missingAccountFunds
    ) external returns (uint256 validationData) {
        //todo
    }

    function isValidSignature(bytes32 userOpHash, bytes calldata signature) 
        external view returns (bytes4 magicValue) 
    {
        //todo
    }
}