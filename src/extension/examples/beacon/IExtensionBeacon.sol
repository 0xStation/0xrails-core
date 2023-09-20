// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IExtensionBeacon {
    error ExtensionUpdatedAfter(bytes4 selector, uint40 updatedAt, uint40 updateThreshold);

    /// @dev Function to get the extension contract address extending a specific func selector.
    /// @param selector The function selector to query for its extension.
    /// @return updatedBefore The uint40 timestamp of update
    function extensionOf(bytes4 selector, uint40 updatedBefore) external view returns (address implementation);
}

interface IExtensionBeaconFollower {
    event ExtensionBeaconUpdated(address indexed oldBeacon, address indexed newBeacon, uint40 lastValidUpdatedAt);

    /// @dev Function to remove the extension beacon.
    function removeExtensionBeacon() external;

    /// @dev Function to refresh the extension beacon.
    /// @param lastValidUpdatedAt The uint40 timestamp to be set as valid
    function refreshExtensionBeacon(uint40 lastValidUpdatedAt) external;

    /// @dev Function to update the extension beacon.
    /// @param implementation The address to set as new extension beacon
    /// @param lastValidUpdatedAt The uint40 timestamp to be set as valid
    function updateExtensionBeacon(address implementation, uint40 lastValidUpdatedAt) external;
}
