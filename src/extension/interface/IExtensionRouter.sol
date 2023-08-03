// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IExtensionRouter {
    struct ExtensionData {
        uint24 index; //           [0..23]
        uint40 updatedAt; //       [24..63]
        address implementation; // [64..223]
    }

    struct Extension {
        bytes4 selector;
        address implementation;
        uint40 updatedAt;
        string signature;
    }

    event ExtensionUpdated(bytes4 indexed selector, address indexed oldExtension, address indexed newExtension);

    error ExtensionDoesNotExist(bytes4 selector);
    error ExtensionAlreadyExists(bytes4 selector);
    error ExtensionUnchanged(bytes4 selector, address oldImplementation, address newImplementation);

    // views
    function extensionOf(bytes4 selector) external view returns (address implementation);
    function getAllExtensions() external view returns (Extension[] memory extensions);
    // setters
    function addExtension(bytes4 selector, address implementation) external;
    function removeExtension(bytes4 selector) external;
    function updateExtension(bytes4 selector, address implementation) external;
}
