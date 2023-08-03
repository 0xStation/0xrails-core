// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface InterfaceInternal {
    // events

    // errors

    // views
    function foo() external;
}

interface InterfaceExternal {
    // setters
    function bar() external;
}

interface Interface is InterfaceInternal, InterfaceExternal {}
