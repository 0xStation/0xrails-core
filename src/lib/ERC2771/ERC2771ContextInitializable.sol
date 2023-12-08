// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Context} from "openzeppelin-contracts/utils/Context.sol";

/// @title GroupOS ERC2771ContextInitializable
/// @author 👦🏻👦🏻.eth
/// @dev ERC2771Context variant enabling support for meta transactions in proxy contracts
/// without the use of a constructor which would alter the create2 deployment address.
/// Child contracts must call the `_forwarderInitializer()` in their proxy initializers
abstract contract ERC2771ContextInitializable is Context {
    /// @dev To maximize trustlessness, the ERC2771 forwarder is treated as a singleton
    address private _trustedForwarder;

    /// @dev Returns the address of the trusted forwarder
    function trustedForwarder() public view virtual returns (address) {
        return _trustedForwarder;
    }

    /// @dev Returns whether a given address is the trusted forwarder
    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    /// @dev Must be called by child contracts in their proxy `initialize()` function.
    /// As proxies cannot use constructors, the forwarder address cannot be declared `immutable`
    function _forwarderInitializer(address trustedForwarder_) internal virtual {
        _trustedForwarder = trustedForwarder_;
    } 

    /// @dev Override of `msg.sender` which returns an EOA originator if the Forwarder
    /// successfully authenticated the originator signed a meta-transaction
    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            sender = address(bytes20(msg.data[msg.data.length - 20:]));
        } else {
            return super._msgSender();
        }
    }

    /// @dev Override of `msg.data` which returns the relevant calldata if the Forwarder
    /// successfully authenticated the data signer and appended signer address to calldata
    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}
