// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IPaymaster} from "src/lib/ERC4337/interface/IPaymaster.sol";
import {PaymasterInternal} from "src/lib/ERC4337/PaymasterInternal.sol";
import {ERC4337Internal} from "src/lib/ERC4337/utils/ERC4337Internal.sol";
import {UserOperation} from "src/lib/ERC4337/utils/UserOperation.sol";

/// @title Station Network Paymaster Contract
/// @author 👦🏻👦🏻.eth

/// @dev ERC-4337 Paymaster contract enabling support for Account Abstraction  
/// within GroupOS's modular smart contract coordination system: Mage 🧙
contract Paymaster is IPaymaster, PaymasterInternal {

    /*====================
        MAGE PAYMASTER
    ====================*/

    function validatePaymasterUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 maxCost)
        external override returns (bytes memory context, uint256 validationData) 
    {
        _checkSenderIsEntryPoint();
        return _validatePaymasterUserOp(userOp, userOpHash, maxCost);
    }



    function postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) external override {
        _checkSenderIsEntryPoint();
        _postOp(mode, context, actualGasCost);
    }

    
    //TODO move these into PaymasterInternal.sol
        function _validatePaymasterUserOp(
            UserOperation calldata userOp, 
            bytes32 userOpHash, 
            uint256 maxCost
        ) internal view virtual returns (bytes memory context, uint256 validationData) 
    {
        //todo
    }

        function _postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) internal virtual {
            //todo
        }
}