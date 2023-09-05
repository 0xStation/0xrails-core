// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Address} from "openzeppelin-contracts/utils/Address.sol";

abstract contract Execute {
    event Executed(address indexed executor, address indexed to, uint256 value, bytes data);

    function call(address to, uint256 value, bytes calldata data) public returns (bytes memory executeData) {
        _checkCanCall();
        (address guard, bytes memory checkBeforeData) = _beforeCall(to, value, data);
        executeData = Address.functionCallWithValue(to, data, value); // library checks for contract existence
        _afterCall(guard, checkBeforeData, executeData);
        emit Executed(msg.sender, to, value, data);
        return executeData;
    }

    function _checkCanCall() internal view virtual;

    function _beforeCall(address to, uint256 value, bytes calldata data) internal virtual returns (address guard, bytes memory checkBeforeData);

    function _afterCall(address guard, bytes memory checkBeforeData, bytes memory executeData) internal virtual;
}
