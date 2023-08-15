// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Operations {
    bytes8 constant ADMIN = 0xfd45ddde6135ec42; // hashOperation("ADMIN");
    bytes8 constant MINT = 0x38381131ea27ecba; // hashOperation("MINT");
    bytes8 constant BURN = 0xf951edb3fd4a16a3; // hashOperation("BURN");
    bytes8 constant TRANSFER = 0x5cc15eb80ba37777; // hashOperation("TRANSFER");
    bytes8 constant METADATA = 0x0e5de49ee56c0bd3; // hashOperation("METADATA");

    // TODO: deprecate and find another way versus anti-pattern
    // permits are enabling the permission, but only through set up modules/extension logic
    // e.g. someone can approve new members to mint, but cannot circumvent the module for taking payment
    bytes8 constant MINT_PERMIT = 0x0b6c53f325d325d3; // hashOperation("MINT_PERMIT");
    bytes8 constant BURN_PERMIT = 0x6801400fea7cd7c7; // hashOperation("BURN_PERMIT");
    bytes8 constant TRANSFER_PERMIT = 0xa994951607abf93b; // hashOperation("TRANSFER_PERMIT");
    bytes8 constant METADATA_PERMIT = 0x2af95d8d71827d12; // hashOperation("METADATA_PERMIT");

    function nameOperation(bytes8 operation) public pure returns (string memory name) {
        if (operation == ADMIN) {
            return "ADMIN";
        } else if (operation == MINT) {
            return "MINT";
        } else if (operation == BURN) {
            return "BURN";
        } else if (operation == TRANSFER) {
            return "TRANSFER";
        } else if (operation == METADATA) {
            return "METADATA";
        } else if (operation == MINT_PERMIT) {
            return "MINT_PERMIT";
        } else if (operation == BURN_PERMIT) {
            return "BURN_PERMIT";
        } else if (operation == TRANSFER_PERMIT) {
            return "TRANSFER_PERMIT";
        } else if (operation == METADATA_PERMIT) {
            return "METADATA_PERMIT";
        }
    }
}
