// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC721Internal, IERC721Receiver} from "./IERC721.sol";
import {ERC721Storage} from "./ERC721Storage.sol";

abstract contract ERC721Internal is IERC721Internal {
    /*===========
        VIEWS
    ===========*/

    function name() external virtual returns (string memory);
    
    function symbol() external virtual returns (string memory);

    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    function totalSupply() public view virtual returns (uint256) {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return layout.currentIndex - layout.burnCounter - _startTokenId();
        }
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        return layout.owners[owner].balance;
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory);

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return _dataOf(tokenId).owner;
    }
    
    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _dataOf(uint256 tokenId) private view returns (ERC721Storage.TokenData memory) {
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

    // APPROVALS

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        return _startTokenId() <= tokenId && tokenId < layout.currentIndex // If within bounds,
            && !layout.tokens[tokenId].burned; // and not burned.
    }

    function _approve(address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ApprovalInvalidOperator();
        }
        address owner = ownerOf(tokenId);

        if (msg.sender != owner) {
            if (!isApprovedForAll(owner, msg.sender)) {
                revert ApprovalCallerNotOwnerNorApproved();
            }
        }
        
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        layout.tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function _setApprovalForAll(address operator, bool approved) internal {
        if (operator == address(0)) {
            revert ApprovalInvalidOperator();
        }
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        layout.operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return layout.tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        return layout.operatorApprovals[owner][operator];
    }

    /*===============
        OWNERSHIP
    ===============*/

    function _mint(address to, uint256 quantity) internal {
        if (quantity == 0) revert MintZeroQuantity();
        if (to == address(0)) revert MintToZeroAddress();

        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        
        uint256 startTokenId = layout.currentIndex;

        bytes memory beforeCheckData = _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        ERC721Storage.OwnerData storage ownerData = layout.owners[to];
        ownerData.balance += uint64(quantity);
        ownerData.numMinted += uint64(quantity);

        ERC721Storage.TokenData memory tokenData = ERC721Storage.TokenData(to, false, quantity == 1);
        layout.tokens[startTokenId] = tokenData;

        uint256 endIndex = startTokenId + quantity;
        for (uint256 tokenId = startTokenId; tokenId < endIndex; tokenId++) {
            emit Transfer(address(0), to, tokenId);
        }
        layout.currentIndex = uint64(endIndex);
        
        _afterTokenTransfers(beforeCheckData);
    }

    function _burn(uint256 tokenId) internal {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        ERC721Storage.TokenData memory previousTokenData = _dataOf(tokenId); // reverts if tokenId is burned
        address from = previousTokenData.owner;
        ERC721Storage.OwnerData storage ownerData = layout.owners[from];

        // approvals?

        bytes memory beforeCheckData = _beforeTokenTransfers(from, address(0), tokenId, 1);

        // clear approval from previous owner
        delete layout.tokenApprovals[tokenId];

        ownerData.balance -= 1;
        ownerData.numBurned += 1;

        // if next token is potentially uninitialized
        if (!previousTokenData.nextInitialized) {
            uint256 nextTokenId = tokenId + 1;
            // if nextTokenId has been minted
            if (nextTokenId < layout.currentIndex) {
                ERC721Storage.TokenData storage nextTokenData = layout.tokens[nextTokenId];
                // if next token is unowned
                if (nextTokenData.owner == address(0) && !nextTokenData.burned) {
                    // then implicit owner is previous token owner
                    nextTokenData.owner = previousTokenData.owner;
                    // default burned: false
                    // default nextInitialized: false
                }
            }
        }

        ERC721Storage.TokenData storage tokenData = layout.tokens[tokenId];
        tokenData.burned = true;
        tokenData.nextInitialized = true;
        tokenData.owner = address(0); // not part of official 721A

        layout.burnCounter++;

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(beforeCheckData);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        ERC721Storage.TokenData memory previousTokenData = _dataOf(tokenId); // reverts if tokenId is burned
        ERC721Storage.OwnerData storage fromOwnerData = layout.owners[from];
        ERC721Storage.OwnerData storage toOwnerData = layout.owners[to];

        if (previousTokenData.owner != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        // approvals?

        bytes memory beforeCheckData = _beforeTokenTransfers(from, to, tokenId, 1);

        // clear approval from previous owner
        delete layout.tokenApprovals[tokenId];

        --fromOwnerData.balance;
        ++toOwnerData.balance;

        ERC721Storage.TokenData storage tokenData = layout.tokens[tokenId];
        tokenData.owner = to;
        tokenData.nextInitialized = true;

        // if next token is potentially uninitialized
        if (!previousTokenData.nextInitialized) {
            uint256 nextTokenId = tokenId + 1;
            // if nextTokenId has been minted
            if (nextTokenId < layout.currentIndex) {
                ERC721Storage.TokenData storage nextTokenData = layout.tokens[nextTokenId];
                // if next token is unowned
                if (nextTokenData.owner == address(0) && !nextTokenData.burned) {
                    // then implicit owner is previous token owner
                    nextTokenData.owner = previousTokenData.owner;
                    // default burned: false
                    // default nextInitialized: false
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(beforeCheckData);
    }

    function _safeMint(address to, uint256 quantity) internal virtual {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = layout.currentIndex;
                uint256 index = end - quantity;
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
        AUTHORITZATION
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

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual returns (bytes memory) {}

    function _afterTokenTransfers(bytes memory beforeCheckData) internal virtual {}
}
