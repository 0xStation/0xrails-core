// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IAccountFactory {
    event AccountImplUpdated(address indexed accountImpl);
    event AccountCreated(address indexed account);

    error InvalidImplementation();

    function simulateCreate2(bytes32 salt, bytes32 creationCodeHash) external view returns (address);
    function setAccountImpl(address newAccountImpl) external;
    function getAccountImpl() external view returns (address);
}
