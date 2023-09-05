// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {BotAccount} from "src/lib/ERC4337/account/BotAccount.sol";
// import {MemberAccount} from "src/lib/ERC4337/account/MemberAccount.sol";
// import {GroupAccount} from "src/lib/ERC4337/account/GroupAccount.sol";
import {IAccountFactory} from "src/lib/ERC4337/account/factory/IAccountFactory.sol";
import {AccountFactoryStorage} from "src/lib/ERC4337/account/factory/AccountFactoryStorage.sol";
import {Initializable} from "src/lib/initializable/Initializable.sol";
import {Ownable} from "src/access/ownable/Ownable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts/proxy/utils/UUPSUpgradeable.sol";

/// @title Station Network Account Factory Contract
/// @author 👦🏻👦🏻.eth

/// @dev This AccountFactory contract uses the `CREATE2` opcode to deterministically
/// deploy a new ERC1271 and ERC4337 compliant Account to a counterfactual address.
/// Deployments can be precomputed using the deployer address,
contract AccountFactory is Initializable, Ownable, UUPSUpgradeable, IAccountFactory {

    /*====================
        INITIALIZATION
    ====================*/

    constructor() Initializable() {}

    function initialize(
        address _botAccountImpl, /*
        address _memberAccountImpl, 
        address _groupAccountImpl */
        address _owner
    ) external initializer {
        _updateAccountImpl(_botAccountImpl, AccountType.BOT);
        // _updateAccountImpl(_memberAccountImpl, AccountType.MEMBER);
        // _updateAccountImpl(_groupAccountImpl, AccountType.GROUP);

        _transferOwnership(_owner);
    }


    /*====================
        ACCOUNTFACTORY
    ====================*/

    /// @dev Function to deploy a new Account using the `CREATE2` opcode
    function create2(bytes32 salt, AccountType accountType) external returns (address newAccount) {
        //todo
        emit AccountCreated(newAccount, accountType);
    }

    function setAccountImpl(address newAccountImpl, AccountType accountType) external onlyOwner {
        _updateAccountImpl(newAccountImpl, accountType);
    }

    function getAccountImpl(AccountType accountType) public view returns (address) {
        return AccountFactoryStorage.layout().accountImpls[uint8(accountType)];
    }

    /*===============
        INTERNALS
    ===============*/

    function _updateAccountImpl(address _newAccountImpl, AccountType _accountType) internal {
        if (_newAccountImpl == address(0x0)) revert InvalidImplementation();

        AccountFactoryStorage.Layout storage layout = AccountFactoryStorage.layout();
        layout.accountImpls[uint8(_accountType)] = _newAccountImpl;

        emit AccountImplUpdated(_newAccountImpl, _accountType);
    }

    // function _precomputeAccountAddress() //todo

    /*===============
        OVERRIDES
    ===============*/

    /// @dev Only the owner may authorize a UUPS upgrade
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}