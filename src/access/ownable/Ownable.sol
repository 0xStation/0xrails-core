// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {OwnableInternal} from "./OwnableInternal.sol";
import {IOwnableExternal} from "./interface/IOwnable.sol";

/// @title 0xRails Ownable contract
/// @dev This contract provides access control by defining an owner address,
/// which can be updated through a two-step pending acceptance system or even revoked if desired.
abstract contract Ownable is OwnableInternal, IOwnableExternal {
    /*=============
        SETTERS
    =============*/

    /// @inheritdoc IOwnableExternal
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _startOwnershipTransfer(newOwner);
    }

    /// @inheritdoc IOwnableExternal
    function acceptOwnership() public virtual {
        _acceptOwnership();
    }
}
