// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Rails} from "../../Rails.sol";
import {Ownable, OwnableInternal} from "../../access/ownable/Ownable.sol";
import {Access} from "../../access/Access.sol";
import {Operations} from "../../lib/Operations.sol";
import {Initializable} from "../../lib/initializable/Initializable.sol";

import {AccountCollection} from "./AccountCollection.sol";
import {IAccountCollectionRails} from "./interface/IAccountCollectionRails.sol";

contract AccountCollectionRails is IAccountCollectionRails, AccountCollection, Initializable, Ownable, Rails {
    function initialize(address owner_, address initializerImpl_) external initializer {
        _transferOwnership(owner_);
        _setAccountInitializer(initializerImpl_);
    }

    /// @dev Owner address is implemented using the `OwnableInternal` contract's function
    function owner() public view override(Access, OwnableInternal) returns (address) {
        return OwnableInternal.owner();
    }

    /*===================
        AUTHORIZATION
    ===================*/

    function _checkCanUpdateAccountInitializer() internal view override {
        _checkPermission(Operations.ACCOUNT_INITIALIZER, msg.sender);
    }

    /// @dev Restrict Permissions write access to the `Operations.PERMISSIONS` permission
    function _checkCanUpdatePermissions() internal view override {
        _checkPermission(Operations.PERMISSIONS, msg.sender);
    }

    /// @dev Restrict Guards write access to the `Operations.GUARDS` permission
    function _checkCanUpdateGuards() internal view override {
        _checkPermission(Operations.GUARDS, msg.sender);
    }

    /// @dev Restrict calls via Execute to the `Operations.EXECUTE` permission
    function _checkCanExecuteCall() internal view override {
        _checkPermission(Operations.CALL, msg.sender);
    }

    /// @dev Restrict ERC-165 write access to the `Operations.INTERFACE` permission
    function _checkCanUpdateInterfaces() internal view override {
        _checkPermission(Operations.INTERFACE, msg.sender);
    }

    /// @dev Only the `owner` possesses Extensions write access
    function _checkCanUpdateExtensions() internal view override {
        // changes to core functionality must be restricted to owners to protect admins overthrowing
        _checkOwner();
    }

    /// @dev Only the `owner` possesses UUPS upgrade rights
    function _authorizeUpgrade(address) internal view override {
        // changes to core functionality must be restricted to owners to protect admins overthrowing
        _checkOwner();
    }
}
