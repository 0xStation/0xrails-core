// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library ERC6551AccountGroupLib {
    function accountGroup() internal view returns (address) {
        bytes memory snippet = new bytes(0x20);
        assembly {
            // save to 32 (0x20) bytes after snippet pointer
            // start reading 10 (0xa) bytes into the contracts bytecode
            // copy 20 (0x14) bytes from end of snippet
            extcodecopy(address(), add(snippet, 0x20), 0xa, 0x14)
        }
        // snippet = 0x{address}{10bytes}
        return address(abi.decode(snippet, (bytes20)));
    }
}
