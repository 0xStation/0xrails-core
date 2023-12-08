// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC2771ContextInitializable} from "./IERC2771ContextInitializable.sol";

/// @title GroupOS ERC2771ContextInitializable
/// @author 👦🏻👦🏻.eth
/// @dev ERC2771Context variant enabling support for meta transactions in proxy contracts
/// without the use of a constructor which would alter the create2 deployment address.
/// Child contracts must call this contract's `_initialize()` function in their proxy initializers
/// @notice Contracts that use this contract with `Multicall` must be careful not to introduce
/// a `_msgSender()` address poisoning vulnerability. To mitigate, GroupOS uses OpenZeppelin v4.9.4
abstract contract ERC2771ContextInitializable is IERC2771ContextInitializable {
    /// @dev To maximize trustlessness, the ERC2771 forwarder is treated as a singleton
    address private _trustedForwarder;

    /// @inheritdoc IERC2771ContextInitializable
    function trustedForwarder() public view virtual returns (address) {
        return _trustedForwarder;
    }

    /// @inheritdoc IERC2771ContextInitializable
    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    /// @dev Override of `msg.sender` which returns an EOA originator if the Forwarder
    /// successfully authenticated the originator signed a meta-transaction
    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            sender = address(bytes20(msg.data[msg.data.length - 20:]));
        } else {
            return msg.sender;
        }
    }

    /// @dev Override of `msg.data` which returns the relevant calldata if the Forwarder
    /// successfully authenticated the data signer and appended signer address to calldata
    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

    /// @dev Must be called by child contracts in their proxy `initialize()` function.
    function _forwarderInitializer(address trustedForwarder_) internal virtual {
        _setForwarder(trustedForwarder_);
    }

    /// As proxies cannot use constructors, the forwarder address cannot be declared `immutable`
    function _setForwarder(address trustedForwarder_) internal virtual {
        _trustedForwarder = trustedForwarder_;
    } 
}
