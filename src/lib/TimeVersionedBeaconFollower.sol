// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Address} from "openzeppelin-contracts/utils/Address.sol";

library TimeVersionedBeaconFollower {
    struct TimeVersionedBeacon {
        address implementation;
        uint40 lastValidUpdatedAt;
    }

    /*=============
        SETTERS
    =============*/

    /// @dev Remove the reference to the implementation from the TimeVersionedBeacon.
    /// @param beacon The TimeVersionedBeacon in storage to remove.
    function remove(TimeVersionedBeacon storage beacon) internal {
        set(beacon, address(0), 0);
    }

    /// @dev Refresh the TimeVersionedBeacon with a new timestamp.
    /// @param beacon The TimeVersionedBeacon in storage to refresh.
    /// @param lastValidUpdatedAt The new timestamp of last valid update.
    function refresh(TimeVersionedBeacon storage beacon, uint40 lastValidUpdatedAt) internal {
        set(beacon, beacon.implementation, lastValidUpdatedAt);
    }

    /// @dev Update the TimeVersionedBeacon with a new implementation and timestamp.
    /// @param beacon The TimeVersionedBeacon storage to update.
    /// @param implementation The new implementation address to set.
    /// @param lastValidUpdatedAt The new timestamp of last valid update.
    function update(TimeVersionedBeacon storage beacon, address implementation, uint40 lastValidUpdatedAt) internal {
        require(implementation != address(0));
        require(lastValidUpdatedAt > 0);
        set(beacon, implementation, lastValidUpdatedAt);
    }

    /*===============
        INTERNALS
    ===============*/

    /// @dev Internal function to set the implementation and lastValidUpdatedAt of a TimeVersionedBeacon.
    /// @param beacon The TimeVersionedBeacon storage to update.
    /// @param implementation The new implementation address to set.
    /// @param lastValidUpdatedAt The new timestamp of last valid update.
    function set(TimeVersionedBeacon storage beacon, address implementation, uint40 lastValidUpdatedAt) internal {
        beacon.implementation = implementation;
        beacon.lastValidUpdatedAt = lastValidUpdatedAt;
    }
}
