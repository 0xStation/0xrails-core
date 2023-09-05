// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IAccountFactory {
    // predefine forward-compatibility with expected new account types
    enum AccountType{ BOT, MEMBER, GROUP }

    event AccountImplUpdated(address indexed accountImpl, AccountType accountType);
    event AccountCreated(address indexed account, AccountType accountType);

    error InvalidImplementation();

    function initialize(
        address _botAccountImpl, /*
        address _memberAccountImpl, 
        address _groupAccountImpl,*/
        address _owner
    ) external;

    function create2(bytes32 salt, AccountType accountType) external returns (address membership);
    function setAccountImpl(address newAccountImpl, AccountType accountType) external;
    function getAccountImpl(AccountType accountType) external view returns (address);
}