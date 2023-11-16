// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ISupportsInterface} from "./ISupportsInterface.sol";
import {SupportsInterfaceStorage} from "./SupportsInterfaceStorage.sol";

abstract contract SupportsInterface is ISupportsInterface {

    /// @dev For explicit EIP165 compliance, the interfaceId of the standard IERC165 implementation
    /// which is derived from `bytes4(keccak256('supportsInterface(bytes4)'))`
    /// is stored directly as a constant in order to preserve Rails's ERC7201 namespace pattern
    bytes4 public constant erc165Id = 0x01ffc9a7;

    /*===========
        VIEWS
    ===========*/

    /// @inheritdoc ISupportsInterface
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return _supportsInterface(interfaceId);
    }

    /*=============
        SETTERS
    =============*/

    /// @inheritdoc ISupportsInterface
    function addInterface(bytes4 interfaceId) external virtual canUpdateInterfaces {
        _addInterface(interfaceId);
    }

    /// @inheritdoc ISupportsInterface
    function removeInterface(bytes4 interfaceId) external virtual canUpdateInterfaces {
        _removeInterface(interfaceId);
    }

    /*===============
        INTERNALS
    ===============*/

    /// @dev To remain EIP165 compliant, this function must not be called with `bytes4(type(uint32).max)`
    /// Setting `0xffffffff` as true by providing it as `interfaceId` will disable support of EIP165 in child contracts
    function _supportsInterface(bytes4 interfaceId) internal view returns (bool) {
        SupportsInterfaceStorage.Layout storage layout = SupportsInterfaceStorage.layout();
        return interfaceId == erc165Id || layout._supportsInterface[interfaceId];
    }

    function _addInterface(bytes4 interfaceId) internal {
        SupportsInterfaceStorage.Layout storage layout = SupportsInterfaceStorage.layout();
        if (layout._supportsInterface[interfaceId]) revert InterfaceAlreadyAdded(interfaceId);
        layout._supportsInterface[interfaceId] = true;
    }

    function _removeInterface(bytes4 interfaceId) internal {
        SupportsInterfaceStorage.Layout storage layout = SupportsInterfaceStorage.layout();
        if (!layout._supportsInterface[interfaceId]) revert InterfaceNotAdded(interfaceId);
        delete layout._supportsInterface[interfaceId];
    }

    /*====================
        AUTHORIZATION
    ====================*/

    modifier canUpdateInterfaces() {
        _checkCanUpdateInterfaces();
        _;
    }

    /// @dev Function to check if caller possesses sufficient permission to set interfaces
    /// @notice Should revert upon failure.
    function _checkCanUpdateInterfaces() internal virtual;
}
