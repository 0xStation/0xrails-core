// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IAccountCollection {
    event AccountInitializerUpdated(address oldImpl, address newImpl);

    function getAccountInitializer() external view returns (address);
    function setAccountInitializer(address initializer) external;
}
