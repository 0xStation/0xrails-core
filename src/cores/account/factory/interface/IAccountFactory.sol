// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IAccountFactory {
    event AccountImplUpdated(address indexed accountImpl);
    event AccountCreated(address indexed account);

    error InvalidImplementation();

    /// @dev Function to simulate a `CREATE2` deployment using a given salt and desired AccountType
    function simulateCreate2(bytes32 salt, bytes32 creationCodeHash) external view returns (address);
    /// @dev Function to set the implementation address whose logic will be used by deployed account proxies
    function setAccountImpl(address newAccountImpl) external;
    /// @dev Function to get the implementation address whose logic is used by deployed account proxies
    function getAccountImpl() external view returns (address);
}
