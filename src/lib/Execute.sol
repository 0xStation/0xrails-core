// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Address} from "openzeppelin-contracts/utils/Address.sol";

abstract contract Execute {
    event Executed(address indexed executor, address indexed to, uint256 value, bytes data);

    function executeCall(address to, uint256 value, bytes calldata data) public returns (bytes memory executeData) {
        _checkCanExecuteCall();
        (address guard, bytes memory checkBeforeData) = _beforeExecuteCall(to, value, data);
        executeData = Address.functionCallWithValue(to, data, value); // library checks for contract existence
        _afterExecuteCall(guard, checkBeforeData, executeData);
        emit Executed(msg.sender, to, value, data);
        return executeData;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(Execute).interfaceId;
    }

    function _checkCanExecuteCall() internal view virtual;

    function _beforeExecuteCall(address to, uint256 value, bytes calldata data) internal virtual returns (address guard, bytes memory checkBeforeData);

    function _afterExecuteCall(address guard, bytes memory checkBeforeData, bytes memory executeData) internal virtual;
}
