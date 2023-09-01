// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC1155Receiver} from "openzeppelin-contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC1155} from "./interface/IERC1155.sol";
import {ERC1155Storage} from "./ERC1155Storage.sol";

abstract contract ERC1155 is IERC1155 {

    /*==============
        METADATA
    ==============*/

    /// @dev require override
    function name() public view virtual returns (string memory);

    /// @dev require override
    function symbol() public view virtual returns (string memory);

    /// @dev require override
    function uri(uint256 tokenId) public view virtual returns (string memory);

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return interfaceId == 0x01ffc9a7 // ERC165 interface ID for ERC165.
            || interfaceId == 0xd9b67a26 // ERC165 Interface ID for ERC1155
            || interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*===========
        VIEWS
    ===========*/

    function balanceOf(address account, uint256 id) public view virtual returns (uint256) {
        return ERC1155Storage.layout().balances[id][account];
    }

    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual returns (uint256[] memory) {
        if (accounts.length != ids.length) {
            revert ERC1155InvalidArrayLength(ids.length, accounts.length);
        }

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function isApprovedForAll(address account, address operator) public view virtual returns (bool) {
        return ERC1155Storage.layout().operatorApprovals[account][operator];
    }

    /*======================
        EXTERNAL SETTERS
    ======================*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) public virtual {
        _checkCanTransfer(from);
        _safeTransferFrom(from, to, id, value, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual {
        _checkCanTransfer(from);
        _safeBatchTransferFrom(from, to, ids, values, data);
    }

    /*======================
        INTERNAL SETTERS
    ======================*/

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        if (operator == address(0)) {
            revert ERC1155InvalidOperator(address(0));
        }
        ERC1155Storage.layout().operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) internal {
        (uint256[] memory ids, uint256[] memory values) = _asSingletonArrays(id, value);
        _safeBatchTransferFrom(from, to, ids, values, data);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal {
        if (to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        _updateWithAcceptanceCheck(from, to, ids, values, data);
    }

    function _mint(address to, uint256 id, uint256 value, bytes memory data) internal {
        (uint256[] memory ids, uint256[] memory values) = _asSingletonArrays(id, value);
        _mintBatch(to, ids, values, data);
    }

    function _mintBatch(address to, uint256[] memory ids, uint256[] memory values, bytes memory data) internal {
        if (to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        _updateWithAcceptanceCheck(address(0), to, ids, values, data);
    }

    function _burn(address from, uint256 id, uint256 value) internal {
        (uint256[] memory ids, uint256[] memory values) = _asSingletonArrays(id, value);
        _burnBatch(from, ids, values);
    }

    function _burnBatch(address from, uint256[] memory ids, uint256[] memory values) internal {
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        _updateWithAcceptanceCheck(from, address(0), ids, values, "");
    }

    function _updateWithAcceptanceCheck(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal virtual {
        _update(from, to, ids, values);
        if (to != address(0)) {
            address operator = msg.sender;
            if (ids.length == 1) {
                uint256 id = ids[0];
                uint256 value = values[0];
                _doSafeTransferAcceptanceCheck(operator, from, to, id, value, data);
            } else {
                _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, values, data);
            }
        }
    }

    /// @dev overriden from OZ by adding totalSupply math
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values) internal virtual {
        if (ids.length != values.length) {
            revert ERC1155InvalidArrayLength(ids.length, values.length);
        }
        ERC1155Storage.Layout storage layout = ERC1155Storage.layout();

        // check before
        (address guard, bytes memory beforeCheckData) = _beforeTokenTransfers(from, to, ids, values);

        address operator = msg.sender;

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 value = values[i];

            if (from != address(0)) {
                uint256 fromBalance = layout.balances[id][from];
                if (fromBalance < value) {
                    revert ERC1155InsufficientBalance(from, fromBalance, value, id);
                }
                layout.balances[id][from] = fromBalance - value;
            } else {
                // increase total supply if minting
                layout.totalSupply[id] += value;
            }

            if (to != address(0)) {
                layout.balances[id][to] += value;
            } else {
                // decrease total supply if burning
                layout.totalSupply[id] -= value;
            }
        }

        if (ids.length == 1) {
            uint256 id = ids[0];
            uint256 value = values[0];
            emit TransferSingle(operator, from, to, id, value);
        } else {
            emit TransferBatch(operator, from, to, ids, values);
        }

        // check after
        _afterTokenTransfers(guard, beforeCheckData);
    }

    function _asSingletonArrays(
        uint256 element1,
        uint256 element2
    ) private pure returns (uint256[] memory array1, uint256[] memory array2) {
        /// @solidity memory-safe-assembly
        assembly {
            // Load the free memory pointer
            array1 := mload(0x40)
            // Set array length to 1
            mstore(array1, 1)
            // Store the single element at the next word after the length (where content starts)
            mstore(add(array1, 0x20), element1)

            // Repeat for next array locating it right after the first array
            array2 := add(array1, 0x40)
            mstore(array2, 1)
            mstore(add(array2, 0x20), element2)

            // Update the free memory pointer by pointing after the second array
            mstore(0x40, add(array2, 0x40))
        }
    }

    /*====================
        AUTHORIZATION
    ====================*/

    function _checkCanTransfer(address from) internal virtual {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) {
            revert ERC1155MissingApprovalForAll(msg.sender, from);
        }
    }
    
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, value, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    // Tokens rejected
                    revert ERC1155InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    // non-ERC1155Receiver implementer
                    revert ERC1155InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, values, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    // Tokens rejected
                    revert ERC1155InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    // non-ERC1155Receiver implementer
                    revert ERC1155InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal virtual returns (address guard, bytes memory beforeCheckData);

    function _afterTokenTransfers(address guard, bytes memory checkBeforeData) internal virtual;
}
