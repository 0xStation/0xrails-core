// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ISupportsInterfaceInternal {
    // events
    event InterfaceAdded(bytes4 indexed interfaceId);
    event InterfaceRemoved(bytes4 indexed interfaceId);

    // errors
    error InterfaceAlreadyAdded(bytes4 interfaceId);
    error InterfaceNotAdded(bytes4 interfaceId);
}

interface ISupportsInterfaceExternal {
    // views
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    // setters
    function addInterface(bytes4 interfaceId) external;
    function removeInterface(bytes4 interfaceId) external;
}

interface ISupportsInterface is ISupportsInterfaceInternal, ISupportsInterfaceExternal {}
