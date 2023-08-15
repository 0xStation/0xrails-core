// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC721Internal} from "./IERC721.sol";
import {ERC721Storage} from "./ERC721Storage.sol";

abstract contract Internal is IERC721Internal {
    /*===========
        VIEWS
    ===========*/
    function foo() external virtual {}

    /*=============
        SETTERS
    =============*/

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        if (quantity == 0) revert MintZeroQuantity();
        if (to == address(0)) revert MintToZeroAddress();

        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        
        uint256 startTokenId = layout.currentIndex;

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        ERC721Storage.OwnerData storage ownerData = layout.owners[to];
        ownerData.balance += uint64(quantity);
        ownerData.numMinted += uint64(quantity);

        ERC721Storage.TokenData memory tokenData = ERC721Storage.TokenData(to, false, quantity == 1, false);
        layout.tokens[startTokenId] = tokenData;

        uint256 endIndex = startTokenId + quantity;
        for (uint256 tokenId = startTokenId; tokenId < endIndex; tokenId++) {
            emit Transfer(address(0), to, tokenId);
        }
        layout.currentIndex = endIndex;
        
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        ERC721Storage.TokenData storage tokenData = layout.tokens[tokenId];
        ERC721Storage.OwnerData storage ownerData = layout.owners[tokenData.owner];

        // uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = tokenData.owner;

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        delete layout.tokenApprovals[tokenId];

        ownerData.balance -= 1;
        ownerData.numBurned += 1;

        tokenData.burned = true;
        tokenData.nextInitialized = true;

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /*====================
        AUTHORITZATION
    ====================*/

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual {}
}
