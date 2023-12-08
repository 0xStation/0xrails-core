// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Context} from "openzeppelin-contracts/utils/Context.sol";
import {Permissions} from "./permissions/Permissions.sol";
import {PermissionsStorage} from "./permissions/PermissionsStorage.sol";
import {Operations} from "../lib/Operations.sol";
import {ERC2771ContextInitializable} from "../lib/ERC2771/ERC2771ContextInitializable.sol";

abstract contract Access is Permissions, ERC2771ContextInitializable {
    /// @dev Supports multiple owner implementations, e.g. explicit storage vs NFT-owner (ERC-6551)
    function owner() public view virtual returns (address);

    /// @dev Function to check one of 3 permissions criterion is true: owner, admin, or explicit permission
    /// @param operation The explicit permission to check permission for
    /// @param account The account address whose permission will be checked
    /// @return _ Boolean value declaring whether or not the address possesses permission for the operation
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

    /*=============
        CONTEXT
    =============*/

    function _msgSender() 
        internal 
        view 
        virtual 
        override(Context, ERC2771ContextInitializable) 
        returns (address) 
    {
        return super._msgSender();
    }

    function _msgData() 
        internal 
        view 
        virtual 
        override(ERC2771ContextInitializable, Context) 
        returns (bytes calldata) 
    {
        return super._msgData();
    }
}
