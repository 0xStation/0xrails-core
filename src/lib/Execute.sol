// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Address} from "openzeppelin-contracts/utils/Address.sol";

/// @title Execute - A contract for executing calls to other contracts
/// @notice This abstract contract provides functionality for executing *only* calls to other contracts
abstract contract Execute {
    event Executed(address indexed executor, address indexed to, uint256 value, bytes data);

    /// @dev Execute a call to another contract with the specified target address, value, and data.
    /// @param to The address of the target contract to call.
    /// @param value The amount of native currency to send with the call.
    /// @param data The call's data.
    /// @return executeData The return data from the executed call.
    function executeCall(address to, uint256 value, bytes calldata data) public returns (bytes memory executeData) {
        _checkCanExecuteCall();
        (address guard, bytes memory checkBeforeData) = _beforeExecuteCall(to, value, data);
        executeData = Address.functionCallWithValue(to, data, value); // library checks for contract existence
        _afterExecuteCall(guard, checkBeforeData, executeData);
        emit Executed(msg.sender, to, value, data);
        return executeData;
    }

    /// @dev Function to implement ERC-165 compliance 
    /// @param interfaceId The interface identifier to check.
    /// @return _ Boolean indicating whether the contract supports the specified interface.
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(Execute).interfaceId;
    }

    /// @dev Internal function to check if the caller has permission to execute calls.
    function _checkCanExecuteCall() internal view virtual;

    /// @dev Hook to perform pre-call checks and return guard information.
    function _beforeExecuteCall(address to, uint256 value, bytes calldata data)
        internal
        virtual
        returns (address guard, bytes memory checkBeforeData);

    /// @dev Hook to perform post-call checks.
    function _afterExecuteCall(address guard, bytes memory checkBeforeData, bytes memory executeData)
        internal
        virtual;
}
