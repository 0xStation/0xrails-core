// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC4337 {
    error NotEntryPoint(address notEntryPoint);
    error NotPaymasterAndToken(bytes wrongLength);

    event UserOperationSponsored();
}
