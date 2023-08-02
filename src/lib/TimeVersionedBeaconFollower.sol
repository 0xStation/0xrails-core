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

    function remove(TimeVersionedBeacon storage beacon) internal {
        set(beacon, address(0), 0);
    }

    function refresh(TimeVersionedBeacon storage beacon, uint40 lastValidUpdatedAt) internal {
        set(beacon, beacon.implementation, lastValidUpdatedAt);
    }

    function update(TimeVersionedBeacon storage beacon, address implementation, uint40 lastValidUpdatedAt) internal {
        require(implementation != address(0));
        require(lastValidUpdatedAt > 0);
        set(beacon, implementation, lastValidUpdatedAt);
    }

    /*===============
        INTERNALS
    ===============*/

    function set(TimeVersionedBeacon storage beacon, address implementation, uint40 lastValidUpdatedAt) internal {
        beacon.implementation = implementation;
        beacon.lastValidUpdatedAt = lastValidUpdatedAt;
    }
}
