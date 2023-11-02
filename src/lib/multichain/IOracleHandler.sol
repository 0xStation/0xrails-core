// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract IOracleHandler {
    error NotFromOracle(address sender);
    error OracleQueryFailed();

    function setOracle(address _oracle) external virtual;
}