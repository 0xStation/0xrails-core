// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {ERC4337Internal} from "src/lib/ERC4337/utils/ERC4337Internal.sol";
import {UserOperation} from "src/lib/ERC4337/utils/UserOperation.sol";

contract PaymasterInternal is ERC4337Internal {
    //TODO move internals from Paymaster into this file

    // function _validatePaymasterUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 maxCost)
    //     internal virtual returns (bytes memory context, uint256 validationData)
    // {
    // }

//     function _postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) internal virtual {

    //     (mode,context,actualGasCost); // unused params
    //     // subclass must override this method if validatePaymasterUserOp returns a context
    //     revert("must override");
    // }
}