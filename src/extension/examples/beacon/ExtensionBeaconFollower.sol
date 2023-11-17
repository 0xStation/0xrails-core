// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Extensions} from "../../Extensions.sol";
import {IExtensions} from "../../interface/IExtensions.sol";
import {IExtensionBeacon, IExtensionBeaconFollower} from "./IExtensionBeacon.sol";
import {IExtension} from "../../interface/IExtension.sol";
import {TimeVersionedBeaconFollower as TVBF} from "src/lib/TimeVersionedBeaconFollower.sol";

abstract contract ExtensionBeaconFollower is Extensions, IExtensionBeaconFollower {
    TVBF.TimeVersionedBeacon internal extensionBeacon;

    /*===========
        VIEWS
    ===========*/

    /// @dev Function to get the extension contract address extending a specific func selector.
    /// @param selector The function selector to query for its extension.
    function extensionOf(bytes4 selector) public view override returns (address implementation) {
        implementation = super.extensionOf(selector);
        if (implementation != address(0)) return implementation;

        // no local implementation, fetch from beacon
        TVBF.TimeVersionedBeacon memory beacon = extensionBeacon;
        if (beacon.implementation == address(0)) revert ExtensionDoesNotExist(selector);
        implementation = IExtensionBeacon(beacon.implementation).extensionOf(selector, beacon.lastValidUpdatedAt);
        if (implementation == address(0)) revert ExtensionDoesNotExist(selector);

        return implementation;
    }

    /// @dev Function to get an array of all registered extension contracts.
    /// @return extensions An array containing information about all registered extensions.
    function getAllExtensions() public view override returns (Extension[] memory extensions) {
        Extension[] memory beaconExtensions = IExtensions(extensionBeacon.implementation).getAllExtensions();
        Extension[] memory localExtensions = super.getAllExtensions();
        uint256 lenBeacon = beaconExtensions.length;
        uint256 lenLocal = localExtensions.length;

        // calculate number of overriden selectors
        uint256 numOverrides;
        for (uint256 i; i < lenBeacon; i++) {
            if (hasExtended(beaconExtensions[i].selector)) {
                numOverrides++;
            }
        }
        // create new extensions array with total length without overriden selectors
        uint256 lenTotal = lenLocal + lenBeacon - numOverrides;
        extensions = new Extension[](lenTotal);
        // add non-overriden beacon extensions to return
        uint256 j;
        for (uint256 i; i < lenBeacon; i++) {
            if (!hasExtended(beaconExtensions[i].selector)) {
                extensions[j] = beaconExtensions[i];
                j++;
            }
        }
        // add local extensions to return
        for (uint256 i; i < lenLocal; i++) {
            extensions[j] = localExtensions[i];
            j++;
        }

        return extensions;
    }

    /// @dev Function to implement ERC-165 compliance
    /// @param interfaceId The interface identifier to check.
    /// @return _ Boolean indicating whether the contract supports the specified interface.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IExtensions).interfaceId || interfaceId == type(IExtensionBeaconFollower).interfaceId;
    }

    /*=============
        SETTERS
    =============*/

    /// @inheritdoc IExtensionBeaconFollower
    function removeExtensionBeacon() public virtual canUpdateExtensions {
        TVBF.remove(extensionBeacon);
    }

    /// @inheritdoc IExtensionBeaconFollower
    function refreshExtensionBeacon(uint40 lastValidUpdatedAt) public virtual canUpdateExtensions {
        TVBF.refresh(extensionBeacon, lastValidUpdatedAt);
    }

    /// @inheritdoc IExtensionBeaconFollower
    function updateExtensionBeacon(address implementation, uint40 lastValidUpdatedAt)
        public
        virtual
        canUpdateExtensions
    {
        TVBF.update(extensionBeacon, implementation, lastValidUpdatedAt);
    }
}
