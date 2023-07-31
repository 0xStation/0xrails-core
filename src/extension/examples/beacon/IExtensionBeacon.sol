// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IExtensionBeacon {
    error ExtensionUpdatedAfter(bytes4 selector, uint40 updatedAt, uint40 updateThreshold);

    function extensionOf(bytes4 selector, uint40 updatedBefore) external view returns (address implementation);
}

interface IExtensionBeaconFollower {
    event ExtensionBeaconUpdated(address indexed oldBeacon, address indexed newBeacon, uint40 lastValidUpdatedAt);

    function removeExtensionBeacon() external;
    function refreshExtensionBeacon(uint40 lastValidUpdatedAt) external;
    function updateExtensionBeacon(address implementation, uint40 lastValidUpdatedAt) external;
}
