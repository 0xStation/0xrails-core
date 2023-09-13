// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {InterfaceExternal} from "./Interface.sol";
import {Internal} from "./Internal.sol";
import {Storage} from "./Storage.sol";

abstract contract External is Internal, InterfaceExternal {
    /*===========
        VIEWS
    ===========*/

    /*=============
        SETTERS
    =============*/
    function bar() external virtual {}

    /*====================
        AUTHORIZATION
    ====================*/
}
