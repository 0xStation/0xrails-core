// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Address} from "openzeppelin-contracts/utils/Address.sol";

abstract contract Execute {
    event Executed(address indexed executor, address indexed to, uint256 value, bytes data);

    function execute(address to, uint256 value, bytes calldata data) public returns (bytes memory executeData) {
        _checkCanExecute();
        (address guard, bytes memory checkBeforeData) = _beforeExecute(to, value, data);
        executeData = Address.functionCallWithValue(to, data, value); // library checks for contract existence
        _afterExecute(guard, checkBeforeData, executeData);
        emit Executed(msg.sender, to, value, data);
        return executeData;
    }

    function _checkCanExecute() internal view virtual;

    function _beforeExecute(address to, uint256 value, bytes calldata data) internal virtual returns (address guard, bytes memory checkBeforeData);

    function _afterExecute(address guard, bytes memory checkBeforeData, bytes memory executeData) internal virtual;
}
