// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BotAccount} from "src/cores/account/BotAccount.sol";
import {AccountFactory} from "src/cores/account/factory/AccountFactory.sol";
import {Initializable} from "src/lib/initializable/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts/proxy/utils/UUPSUpgradeable.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @title Station Network Bot Account Factory Contract
/// @author 👦🏻👦🏻.eth

/// @dev This BotAccountFactory deploys a BotAccount using `CREATE2` to a counterfactual address.
contract BotAccountFactory is Initializable, UUPSUpgradeable, AccountFactory {

    /*====================
        INITIALIZATION
    ====================*/

    constructor() Initializable() {}

    function initialize(
        address _botAccountImpl,
        address _owner
    ) external initializer {
        _updateAccountImpl(_botAccountImpl);

        _transferOwnership(_owner);
    }

    /*=======================
        BOTACCOUNTFACTORY
    =======================*/

    /// @dev Function to deploy a new Account using the `CREATE2` opcode
    function createBotAccount(
        bytes32 salt, 
        address botAccountOwner, 
        address callPermitValidator, 
        address[] calldata turnkeys
    ) external returns (address newAccount) {
        newAccount = _createBotAccount(salt, botAccountOwner, callPermitValidator, turnkeys);

        emit AccountCreated(newAccount);
    }

    /// @dev Function to return a simulated address for BotAccount creation using a given salt
    function simulateCreateBotAccount(bytes32 salt) public view returns (address) {
        bytes32 creationCodeHash;
        creationCodeHash = keccak256(type(BotAccount).creationCode);
        return _simulateCreate2(salt, creationCodeHash);
    }

    /*===============
        INTERNALS
    ===============*/

    function _createBotAccount(
        bytes32 _salt, 
        address _botAccountOwner,
        address _callPermitValidator,
        address[] memory _turnkeys
    ) internal returns (address payable newBotAccount) {
        newBotAccount = payable(address(new ERC1967Proxy{salt: _salt}(getAccountImpl(), '')));

        BotAccount(newBotAccount).initialize(_botAccountOwner, _callPermitValidator, _turnkeys);
    }

    /*===============
        OVERRIDES
    ===============*/

    /// @dev Only the owner may authorize a UUPS upgrade
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}