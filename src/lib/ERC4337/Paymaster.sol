// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IPaymaster} from "src/lib/ERC4337/interface/IPaymaster.sol";
import {PaymasterInternal} from "src/lib/ERC4337/PaymasterInternal.sol";
import {ERC4337Internal} from "src/lib/ERC4337/utils/ERC4337Internal.sol";
import {UserOperation} from "src/lib/ERC4337/utils/UserOperation.sol";

import {IERC721Mage} from "src/cores/ERC721/interface/IERC721Mage.sol";

/// @title Station Network Paymaster Contract
/// @author 👦🏻👦🏻.eth

/// @dev ERC-4337 Paymaster contract enabling support for Account Abstraction  
/// within GroupOS's modular smart contract coordination system: Mage 🧙
contract Paymaster is IPaymaster, PaymasterInternal /*, StablecoinPurchaseModule */ {

    /*====================
        MAGE PAYMASTER
    ====================*/

    function validatePaymasterUserOp(
        UserOperation calldata userOp, 
        bytes32 userOpHash, 
        uint256 maxCost
    ) external override returns (bytes memory context, uint256 validationData) {
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
    ) internal view virtual returns (bytes memory context, uint256 validationData) {
        // paymasterAndData must only be: `abi.encodePacked(address(this), address(token))` (for single mints)
        // todo should batch mints be supported? probably 
        if (userOp.paymasterAndData.length != 40) revert NotPaymasterAndToken(userOp.paymasterAndData);

        // get collection address from calldata
        abi.decode(userOp.callData, ());
        uint256 
        uint256 formattedPrice = mintPriceToStablecoinAmount(
        context = abi.encodePacked(userOp.sender, formattedPrice);


        /// @notice BLS sig aggregator and timestamp expiry are not currently supported by this contract 
        /// so `bytes20(0x0)` and `bytes6(0x0)` suffice. To enable support for aggregator and timestamp expiry,
        /// override the following params
        bytes20 authorizer;
        bytes6 validUntil;
        bytes6 validAfter;

        validationData = uint256(bytes32(abi.encodePacked(authorizer, validUntil, validAfter)));
    }

    function _postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) internal virtual {
        //todo

        emit UserOperationSponsored(address(bytes20(context[0:20])));
    }
}