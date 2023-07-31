// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Address} from "lib/openzeppelin-contracts/contracts/utils/Address.sol";

abstract contract Execute {
    function execute(address target, uint256 value, bytes calldata data) public {
        _checkCanExecute();
        Address.functionCallWithValue(target, data, value); // library checks for target contract existence
    }

    function _checkCanExecute() internal view virtual {}
}
