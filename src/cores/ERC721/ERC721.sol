// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC721, IERC721Receiver} from "./interface/IERC721.sol";
import {ERC721Storage} from "./ERC721Storage.sol";
import {Initializable} from "../../lib/initializable/Initializable.sol";

abstract contract ERC721 is Initializable, IERC721 {

    /// @dev Large batch mints of ERC721A tokens can result in high gas costs upon first transfer of high tokenIds
    /// To improve UX for token owners unaware of this fact, a mint batch size of 500 is enforced
    uint256 public constant MAX_MINT_BATCH_SIZE = 500;

    /*===========
        VIEWS
    ===========*/

    // global token values

    function totalSupply() public view returns (uint256) {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        return layout.currentIndex - layout.burnCounter - _startTokenId();
    }

    function totalMinted() public view returns (uint256) {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        return layout.currentIndex - _startTokenId();
    }

    function totalBurned() public view returns (uint256) {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        return layout.burnCounter;
    }

    // owner values

    function balanceOf(address owner) public view returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        return layout.owners[owner].balance;
    }

    function numberMinted(address owner) public view returns (uint256) {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        return layout.owners[owner].numMinted;
    }

    function numberBurned(address owner) public view returns (uint256) {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        return layout.owners[owner].numBurned;
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return _batchMarkerDataOf(tokenId).owner; // reverts if token not owned
    }

    // approvals

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return layout.tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        return layout.operatorApprovals[owner][operator];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return interfaceId == 0x01ffc9a7 // ERC165 interface ID for ERC165.
            || interfaceId == 0x80ac58cd // ERC165 interface ID for ERC721.
            || interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    /*=============
        SETTERS
    =============*/

    function approve(address to, uint256 tokenId) public virtual {
        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        _checkCanTransfer(from, tokenId);
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        transferFrom(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    /*=================
        INITIALIZER
    =================*/

    function _initialize() internal onlyInitializing {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        layout.currentIndex = _startTokenId();
    }

    /*===============
        INTERNALS
    ===============*/

    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    function _nextTokenId() internal view virtual returns (uint256) {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        return layout.currentIndex;
    }

        /// @notice Returns the token data for the token marking this batch mint
    /// @dev If tokenId was minted in a batch and tokenId is not the first id in the batch,
    ///      then the returned data will be for a different tokenId.
    function _batchMarkerDataOf(uint256 tokenId) private view returns (ERC721Storage.TokenData memory) {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        uint256 curr = tokenId;

        unchecked {
            if (curr >= _startTokenId()) {
                if (curr < layout.currentIndex) {
                    ERC721Storage.TokenData memory data = layout.tokens[curr];
                    // If not burned.
                    if (!data.burned) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `data.owner != address(0) && data.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `data.owner == address(0) && data.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (data.owner == address(0) && !data.burned) {
                            data = layout.tokens[--curr];
                        }
                        return data;
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        return _startTokenId() <= tokenId && tokenId < layout.currentIndex // If within bounds,
            && !layout.tokens[tokenId].burned; // and not burned.
    }

    // approvals

    function _approve(address operator, uint256 tokenId) internal {
        if (operator == address(0)) {
            revert ApprovalInvalidOperator();
        }
        address owner = ownerOf(tokenId);

        if (msg.sender != owner) {
            if (!isApprovedForAll(owner, msg.sender)) {
                revert ApprovalCallerNotOwnerNorApproved();
            }
        }

        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        layout.tokenApprovals[tokenId] = operator;
        emit Approval(owner, operator, tokenId);
    }

    function _setApprovalForAll(address operator, bool approved) internal {
        if (operator == address(0)) {
            revert ApprovalInvalidOperator();
        }
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        layout.operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // token transfers

    function _mint(address to, uint256 quantity) internal {
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > MAX_MINT_BATCH_SIZE) revert ExceedsMaxMintBatchSize(quantity);
        if (to == address(0)) revert MintToZeroAddress();

        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        uint256 startTokenId = layout.currentIndex;

        // check before
        (address guard, bytes memory beforeCheckData) = _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // update global counters
        uint256 endTokenIndex = startTokenId + quantity;
        layout.currentIndex = endTokenIndex;

        // update owner counters
        ERC721Storage.OwnerData storage ownerData = layout.owners[to];
        /// @dev is there a clean way to combine these two operations into one write while preserving the nice syntax?
        ownerData.balance += uint64(quantity);
        ownerData.numMinted += uint64(quantity);

        // update token data
        layout.tokens[startTokenId] = ERC721Storage.TokenData(to, uint48(block.timestamp), false, quantity == 1);

        // emit events
        for (uint256 tokenId = startTokenId; tokenId < endTokenIndex; tokenId++) {
            emit Transfer(address(0), to, tokenId);
        }

        // check after
        _afterTokenTransfers(guard, beforeCheckData);
    }

    /// @dev approval checks are not made in this internal function, make them when wrapping in a public function
    function _burn(uint256 tokenId) internal {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        ERC721Storage.TokenData memory batchMarkerData = _batchMarkerDataOf(tokenId); // reverts if tokenId is burned
        address from = batchMarkerData.owner;

        // check before
        (address guard, bytes memory beforeCheckData) = _beforeTokenTransfers(from, address(0), tokenId, 1);

        // update global counters
        layout.burnCounter++;

        // update owner counters
        ERC721Storage.OwnerData storage ownerData = layout.owners[from];
        /// @dev is there a clean way to combine these two operations into one write while preserving the nice syntax?
        --ownerData.balance;
        ++ownerData.numBurned;

        // update token data
        layout.tokens[tokenId] = ERC721Storage.TokenData(from, uint48(block.timestamp), true, true);

        // clear approval from previous owner
        delete layout.tokenApprovals[tokenId];

        // set next token as new batch marker if it is in the same batch
        if (!batchMarkerData.nextInitialized) {
            // next token is potentially uninitialized
            uint256 nextTokenId = tokenId + 1;
            if (nextTokenId < layout.currentIndex) {
                // nextTokenId has been minted
                ERC721Storage.TokenData storage nextTokenData = layout.tokens[nextTokenId];
                if (nextTokenData.owner == address(0) && !nextTokenData.burned) {
                    /**
                     * next token is uninitialized so set:
                     * - owner = batch marker owner
                     * - ownerUpdatedAt = batch marker ownerUpdatedAt
                     * - burned = false
                     * - nextInitialized = false
                     */
                    layout.tokens[nextTokenId] =
                        ERC721Storage.TokenData(batchMarkerData.owner, batchMarkerData.ownerUpdatedAt, false, false);
                }
            }
        }

        // emit events
        emit Transfer(from, address(0), tokenId);

        // check after
        _afterTokenTransfers(guard, beforeCheckData);
    }

    /// @dev approval checks are not made in this internal function, make them when wrapping in a public function
    function _transfer(address from, address to, uint256 tokenId) internal {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        ERC721Storage.TokenData memory batchMarkerData = _batchMarkerDataOf(tokenId); // reverts if tokenId is burned

        if (batchMarkerData.owner != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        // check before
        (address guard, bytes memory beforeCheckData) = _beforeTokenTransfers(from, to, tokenId, 1);

        // update owner counters
        --layout.owners[from].balance;
        ++layout.owners[to].balance;

        // update token data
        layout.tokens[tokenId] = ERC721Storage.TokenData(to, uint48(block.timestamp), false, true);

        // clear approval from previous owner
        delete layout.tokenApprovals[tokenId];

        // set next token as new batch marker if it is in the same batch
        if (!batchMarkerData.nextInitialized) {
            // next token is potentially uninitialized
            uint256 nextTokenId = tokenId + 1;
            if (nextTokenId < layout.currentIndex) {
                // nextTokenId has been minted
                ERC721Storage.TokenData storage nextTokenData = layout.tokens[nextTokenId];
                if (nextTokenData.owner == address(0) && !nextTokenData.burned) {
                    /**
                     * next token is uninitialized so set:
                     * - owner = batch marker owner
                     * - ownerUpdatedAt = batch marker ownerUpdatedAt
                     * - burned = false
                     * - nextInitialized = false
                     */
                    layout.tokens[nextTokenId] =
                        ERC721Storage.TokenData(batchMarkerData.owner, batchMarkerData.ownerUpdatedAt, false, false);
                }
            }
        }

        // emit events
        emit Transfer(from, to, tokenId);

        // check after
        _afterTokenTransfers(guard, beforeCheckData);
    }

    // safe token transfers

    function _safeMint(address to, uint256 quantity) internal virtual {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = layout.currentIndex;
                uint256 index = end - quantity;
                /// @dev why does this need to be checked in a loop versus once?
                do {
                    _checkOnERC721Received(address(0), to, index++, "");
                } while (index < end);
                // Reentrancy protection.
                if (layout.currentIndex != end) revert();
            }
        }
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    /*====================
        AUTHORIZATION
    ====================*/

    function _checkCanTransfer(address account, uint256 tokenId) internal virtual {
        if (ownerOf(tokenId) != msg.sender) {
            if (!isApprovedForAll(account, msg.sender)) {
                if (getApproved(tokenId) != msg.sender) {
                    revert TransferCallerNotOwnerNorApproved();
                }
            }
        }
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) internal {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert TransferToNonERC721ReceiverImplementer();
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        virtual
        returns (address guard, bytes memory beforeCheckData)
    {}

    function _afterTokenTransfers(address guard, bytes memory beforeCheckData) internal virtual {}
}
