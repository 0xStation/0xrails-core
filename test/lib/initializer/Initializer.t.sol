// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Initializer} from "src/lib/initializer/Initializer.sol";
import {ERC721Mage} from "src/cores/ERC721/ERC721Mage.sol";

contract AccessTest is Test, Initializer {
    ERC721Mage public erc721Mage;

    // to store errors
    bytes err;

    function setUp() public {
    }
}