// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IExtension {
    function contractURI() external view returns (string memory);
    function signatureOf(bytes4 selector) external pure returns (string memory signature);
    function getAllSelectors() external pure returns (bytes4[] memory selectors);
    function getAllSignatures() external pure returns (string[] memory signatures);
}
