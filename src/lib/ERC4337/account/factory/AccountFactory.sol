// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Account} from "src/lib/ERC4337/account/Account.sol";
import {BotAccount} from "src/lib/ERC4337/account/BotAccount.sol";
// import {MemberAccount} from "src/lib/ERC4337/account/MemberAccount.sol";
// import {GroupAccount} from "src/lib/ERC4337/account/GroupAccount.sol";
import {IAccountFactory} from "src/lib/ERC4337/account/factory/IAccountFactory.sol";
import {AccountFactoryStorage} from "src/lib/ERC4337/account/factory/AccountFactoryStorage.sol";
import {Initializable} from "src/lib/initializable/Initializable.sol";
import {Ownable} from "src/access/ownable/Ownable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts/proxy/utils/UUPSUpgradeable.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

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
        AccountFactoryStorage.Layout storage layout = AccountFactoryStorage.layout();
        layout.accountImpls = new address[](3);
        _updateAccountImpl(_botAccountImpl, AccountType.BOT);
        // _updateAccountImpl(_memberAccountImpl, AccountType.MEMBER);
        // _updateAccountImpl(_groupAccountImpl, AccountType.GROUP);

        _transferOwnership(_owner);
    }

    /*====================
        ACCOUNTFACTORY
    ====================*/

    /// @dev Function to deploy a new Account using the `CREATE2` opcode
    function createBotAccount(
        bytes32 salt, 
        address botAccountOwner, 
        address turnkeyValidator, 
        address[] calldata turnkeys
    ) external returns (address newAccount) {
        newAccount = _createBotAccount(salt, botAccountOwner, turnkeyValidator, turnkeys);

        emit AccountCreated(newAccount, AccountType.BOT);
    }

    function setAccountImpl(address newAccountImpl, AccountType accountType) external onlyOwner {
        _updateAccountImpl(newAccountImpl, accountType);
    }

    function getAccountImpl(AccountType accountType) public view returns (address) {
        return AccountFactoryStorage.layout().accountImpls[uint8(accountType)];
    }

    /// @dev Function to simulate a `CREATE2` deployment using a given salt and desired AccountType
    function simulateCreate2(bytes32 salt, AccountType accountType) public view returns (address) {
        bytes32 creationCodeHash;
        if (accountType == AccountType.BOT) creationCodeHash = keccak256(type(BotAccount).creationCode);
        // else if (accountType == AccountType.MEMBER) creationCodeHash = keccak256(type(MemberAccount).creationCode);
        // else if (accountType == AccountType.GROUP) creationCodeHash = keccak256(type(GroupAccount).creationCode);

        return _simulateCreate2(salt, creationCodeHash);
    }

    /*===============
        INTERNALS
    ===============*/

    function _createBotAccount(
        bytes32 _salt, 
        address _botAccountOwner,
        address _turnkeyValidator,
        address[] memory _turnkeys
    ) internal returns (address payable newBotAccount) {
        newBotAccount = payable(address(new ERC1967Proxy{salt: _salt}(getAccountImpl(AccountType.BOT), '')));

        BotAccount(newBotAccount).initialize(_botAccountOwner, _turnkeyValidator, _turnkeys);
    }

    function _createMemberAccount(bytes32 _salt) internal returns (address payable newMemberAccount) {
        //todo
        // newMemberAccount = payable(address(new ERC1967Proxy{salt: _salt}(getAccountImpl(AccountType.MEMBER), '')));
        // MemberAccount(newMemberAccount).initialize();
    }

    function _createGroupAccount(bytes32 _salt) internal returns (address payable newGroupAccount) {
        //todo
        // newGroupAccount = payable(address(new ERC1967Proxy{salt: _salt}(getAccountImpl(AccountType.GROUP), '')));
        // GroupAccount(newGroupAccount).initialize();
    }

    function _updateAccountImpl(address _newAccountImpl, AccountType _accountType) internal {
        if (_newAccountImpl == address(0x0)) revert InvalidImplementation();

        AccountFactoryStorage.Layout storage layout = AccountFactoryStorage.layout();
        layout.accountImpls[uint8(_accountType)] = _newAccountImpl;

        emit AccountImplUpdated(_newAccountImpl, _accountType);
    }

    /** @notice To help visualize the bytes constructed using Yul assembly, here is a deconstructed rundown
    .  For the following hypothetical values. Active memory is shown with a preceding arrow: `->`
    .   `address(this) = 0xbeefbeefbeefbeefbeefbeefbeefbeefbeefbeef`
    .   `salt = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff`
    .   `creationCodeHash = 0xdeaddeaddeaddeaddeaddeaddeaddeaddeaddeaddeaddeaddeaddeaddeaddead`
    .  Load 32-byte word at free memory pointer: ```let ptr := mload(0x40)```
    .    -> 0x0000000000000000000000000000000000000000000000000000000000000000
    .  Store 1-byte create2 constant at 11th index: ```mstore(add(ptr, 0x0b), 0xff)```
    .    -> 0x0000000000000000000000FF0000000000000000000000000000000000000000
    .  Store 20-byte address of deployer (this contract) at 12th index: ```mstore(ptr, address(this)) ```
    .    -> 0x0000000000000000000000FFbeefbeefbeefbeefbeefbeefbeefbeefbeefbeef
    .  Store 32-byte salt at 32nd index, creating a second word: ```mstore(add(ptr, 0x20), salt)```
    .    -> 0x0000000000000000000000FFbeefbeefbeefbeefbeefbeefbeefbeefbeefbeef
    .    -> 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    .  Store 32-byte creationCodeHash at 64th index, creating a third word: ```mstore(add(ptr, 0x40), creationCodeHash)```
    .    -> 0x0000000000000000000000FFbeefbeefbeefbeefbeefbeefbeefbeefbeefbeef
    .    -> 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    .    -> 0xdeaddeaddeaddeaddeaddeaddeaddeaddeaddeaddeaddeaddeaddeaddeaddead
    .  Keccak256 hash above memory layout, ignoring the first 11 empty bytes: ```keccak256(add(ptr, 0x0b), 85)```
    .    -> bytes32(0x...SomeKeccakOutput...)
    .  Solidity automatically discards the last 12 bytes of the 32-byte Keccak output above, leaving a 20-byte address
    */
    function _simulateCreate2(
        bytes32 _salt, 
        bytes32 _creationCodeHash
    ) internal view returns (address simulatedDeploymentAddress) {
        assembly {
            let ptr := mload(0x40) // instantiate free mem pointer
            
            mstore(add(ptr, 0x0b), 0xff) // insert single byte create2 constant at 11th offset (starting from 0)
            mstore(ptr, address()) // insert 20-byte deployer address at 12th offset
            mstore(add(ptr, 0x20), _salt) // insert 32-byte salt at 32nd offset
            mstore(add(ptr, 0x40), _creationCodeHash) // insert 32-byte creationCodeHash at 64th offset

            // hash all inserted data, which is 85 bytes long, starting from 0xff constant at 11th offset
            simulatedDeploymentAddress := keccak256(add(ptr, 0x0b), 85)
        }
    }

    /*===============
        OVERRIDES
    ===============*/

    /// @dev Only the owner may authorize a UUPS upgrade
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}