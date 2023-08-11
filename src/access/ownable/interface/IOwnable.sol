// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IOwnableInternal {
    // events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    // errors
    error OwnerUnauthorizedAccount(address account);
    error OwnerInvalidOwner(address owner);

    // views
    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
}

interface IOwnableExternal {
    // setters
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;
    function acceptOwnership() external;
}

interface IOwnable is IOwnableInternal, IOwnableExternal {}
