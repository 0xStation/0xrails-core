// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";
import {IERC6551Account} from "erc6551/interfaces/IERC6551Account.sol";
import {ERC6551AccountStorage} from "./ERC6551AccountStorage.sol";

abstract contract ERC6551Account is IERC6551Account {
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC6551Account).interfaceId;
    }

    function isValidSigner(address signer, bytes calldata data) external view returns (bytes4 magicValue) {
        if (_isValidSigner(signer, data)) {
            return IERC6551Account.isValidSigner.selector;
        }

        return bytes4(0);
    }

    function token() public view returns (uint256 chainId, address tokenContract, uint256 tokenId) {
        return ERC6551AccountLib.token();
    }

    /// todo: add pattern for updating state whenever contract state changes
    function state() public view returns (uint256) {
        return ERC6551AccountStorage.layout().state;
    }

    function _isValidSigner(address signer, bytes memory) internal view virtual returns (bool);
}
