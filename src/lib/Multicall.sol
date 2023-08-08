// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// inspired by BoringBatchable: https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringBatchable.sol
// also aligns with Uniswap's implementation: https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol
contract Multicall {
    /// @notice Allows atomic call batching on self
    /// @param calls An array of calls to apply
    /// @dev public visibility to use within construction/initialization
    /// @dev non-payable to prevent accidental double-spend on msg.value
    /// @dev code length of this contract intentionally removed (e.g. relative to OZ Multicall) so that we can use multicall when constructing new proxies
    function multicall(bytes[] calldata calls) public {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success) {
                // parse revert message from failed call

                // transaction failed with custom error or silently (without a revert message)
                if (result.length < 68) revert();
                assembly {
                    // slice the sighash
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string))); // remaining data is revert string
            }
        }
    }
}
