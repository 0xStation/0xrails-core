// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library PermissionsStorage {
    bytes32 internal constant SLOT = keccak256(abi.encode(uint256(keccak256("mage.Permissions")) - 1));

    struct Layout {
        uint256[] _permissionKeys;
        mapping(uint256 => PermissionData) _permissions;
    }

    struct PermissionData {
        uint24 index; //              [0..23]
        uint40 updatedAt; //          [24..63]
        bool exists; //              [64-71]
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }

    function _packKey(bytes8 operation, address account) internal pure returns (uint256) {
        // `operation` cast to uint64 to keep it on the small Endian side, packed with account to its left; leftmost 4 bytes remain empty
        return (uint256(uint64(operation)) | uint256(uint160(account)) << 64);
    }

    function _unpackKey(uint256 key) internal pure returns (bytes8 operation, address account) {
        operation = bytes8(uint64(key));
        account = address(uint160(key >> 64));
        return (operation, account);
    }

    function _hashOperation(string memory name) internal pure returns (bytes8) {
        return bytes8(keccak256(abi.encodePacked(name)));
    }
}
