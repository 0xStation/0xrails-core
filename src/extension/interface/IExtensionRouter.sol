// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IExtensionRouter {
    struct ExtensionData {
        uint16 index; // 16 bits
        address implementation; // 160 bits
        uint80 info; // 80 bits
    }

    struct Extension {
        bytes4 selector;
        address implementation;
        string signature;
    }

    event Extend(bytes4 indexed selector, address indexed oldExtension, address indexed newExtension);

    error SelectorNotExtended(bytes4 selector);
    error SelectorAlreadyExtended(bytes4 selector);
    error ExtensionUnchanged(address oldImplementation, address newImplementation);

    // views
    function extensionOf(bytes4 selector) external view returns (address implementation);
    function getAllExtensions() external view returns (Extension[] memory extensions);
    // setters
    function addExtension(bytes4 selector, address implementation) external;
    function removeExtension(bytes4 selector) external;
    function updateExtension(bytes4 selector, address implementation) external;
}
