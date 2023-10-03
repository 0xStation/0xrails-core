// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC6551AccountGroup {
    event ERC6551AccountInitializerUpdated(address oldImpl, address newImpl);

    function getAccountInitializer() external view returns (address);
    function setAccountInitializer(address initializer) external;
}
