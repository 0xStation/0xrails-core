// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IExtensions {
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

    /// @dev Function to check whether the given selector is mapped to an extension contract
    /// @param selector The function selector to query
    /// @return '' Boolean value identifying if the given selector is extended or not
    function hasExtended(bytes4 selector) external view returns (bool);

    /// @dev Function to get the extension contract address extending a specific func selector.
    /// @param selector The function selector to query for its extension.
    /// @return implementation The address of the extension contract for the function.
    function extensionOf(bytes4 selector) external view returns (address implementation);

    /// @dev Function to get an array of all registered extension contracts.
    /// @return extensions An array containing information about all registered extensions.
    function getAllExtensions() external view returns (Extension[] memory extensions);

    /// @dev Function to set a extension contract for a specific function selector.
    /// @param selector The function selector for which to set an extension contract.
    /// @param implementation The address of the extension contract to map to a function.
    function setExtension(bytes4 selector, address implementation) external;

    /// @dev Function to remove the extension contract for a function.
    /// @param selector The function selector for which to remove its extension.
    function removeExtension(bytes4 selector) external;
}
