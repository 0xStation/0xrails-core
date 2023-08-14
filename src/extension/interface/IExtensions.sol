// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IExtensionsInternal {
    struct Extension {
        bytes4 selector;
        address implementation;
        uint40 updatedAt;
        string signature;
    }

    // events
    event ExtensionUpdated(bytes4 indexed selector, address indexed oldExtension, address indexed newExtension);

    // errors
    error ExtensionDoesNotExist(bytes4 selector);
    error ExtensionAlreadyExists(bytes4 selector);
    error ExtensionUnchanged(bytes4 selector, address oldImplementation, address newImplementation);

    // views
    function extensionOf(bytes4 selector) external view returns (address implementation);
    function getAllExtensions() external view returns (Extension[] memory extensions);
}

interface IExtensionsExternal {
    // setters
    function setExtension(bytes4 selector, address implementation) external;
    function removeExtension(bytes4 selector) external;
}

interface IExtensions is IExtensionsInternal, IExtensionsExternal {}
