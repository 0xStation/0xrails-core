// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Permissions} from "./permissions/Permissions.sol";
import {PermissionsStorage} from "./permissions/PermissionsStorage.sol";
import {Operations} from "../lib/Operations.sol";

abstract contract Access is Permissions {
    /// @dev Supports multiple owner implementations, e.g. explicit storage vs NFT-owner (ERC-6551)
    function owner() public view virtual returns (address);

    //todo
    function hasPermission(bytes8 operation, address account) public view override returns (bool) {
        // 3 tiers: has operation permission, has admin permission, or is owner
        if (super.hasPermission(operation, account)) {
            return true;
        }
        if (operation != Operations.ADMIN && super.hasPermission(Operations.ADMIN, account)) {
            return true;
        }
        return account == owner();
    }

    /// @inheritdoc Permissions
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /*===============
        OVERRIDES
    ===============*/

    /// @inheritdoc Permissions
    function _checkCanUpdatePermissions() internal view virtual override;
}
