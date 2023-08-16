// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IGuard {
    function contractURI() external view returns (string memory);
    function checkBefore(address operator, bytes calldata data) external view returns (bytes memory checkBeforeData);
    function checkAfter(bytes calldata checkBeforeData, bytes calldata executionData) external view;
}
