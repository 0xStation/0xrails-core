// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IOwnerInternal {
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

interface IOwnerExternal {
    // setters
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;
    function acceptOwnership() external;
}

interface IOwner is IOwnerInternal, IOwnerExternal {}
