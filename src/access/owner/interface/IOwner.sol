// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IOwnerInternal {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    error OwnerUnauthorizedAccount(address account);
    error OwnerInvalidOwner(address owner);

    // views
    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
}

interface IOwnerExternal {
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;
    function acceptOwnership() external;
}

interface IOwner is IOwnerInternal, IOwnerExternal {}
