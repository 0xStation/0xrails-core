// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library AccountCollectionLib {
    function accountCollection() internal view returns (address) {
        bytes memory footer = new bytes(0x14); // 20 byte address
        assembly {
            // copy 0x14 bytes from end of footer
            extcodecopy(address(), add(footer, 0x20), 0xa, 0x14)
        }
        return abi.decode(footer, (address));
    }
}
