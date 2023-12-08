// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

/// @title NonceBitMap: Address-Keyed Nonce Bitmap for Signature Replay Protection
/// @author symmetry (@symmtry69)
/// @notice Utility for making address-keyed nonce bitmaps for parallelized signature replay protection
abstract contract NonceBitMap {
    /*=============
        STORAGE
    =============*/

    // account => bitmap for tracking nonces, bitmaps used for gas efficient parallel processing
    mapping(address => mapping(uint256 => uint256)) internal _usedNonces;

    /*============
        EVENTS
    ============*/

    event NonceUsed(address indexed account, uint256 indexed nonce);

    /*===========
        ERRORS
    ===========*/

    error NonceAlreadyUsed(address account, uint256 nonce);

    /*==================
        VERIFICATION
    ==================*/

    /// @dev Check if a nonce has been used for a specific account.
    /// @param account The address for which to check nonce usage.
    /// @param nonce The nonce to check.
    /// @return '' Whether the nonce has been used or not.
    function isNonceUsed(address account, uint256 nonce) public view returns (bool) {
        (, uint256 word, uint256 mask) = _split(account, nonce);
        return word & mask != 0;
    }

    function lastUsedNonce(address account, uint256 wordId) public view returns (uint256) {
        return _usedNonces[account][wordId];
    }

    /// @dev Mark a `nonce` as used for a specific `account`, preventing potential replay attacks.
    function _useNonce(address account, uint256 nonce) internal {
        (uint256 wordId, uint256 word, uint256 mask) = _split(account, nonce);
        if (word & mask != 0) revert NonceAlreadyUsed(account, nonce);
        _usedNonces[account][wordId] = word | mask;
        emit NonceUsed(account, nonce);
    }

    /// @dev Split a nonce into `wordId`, `word`, and `mask` for efficient storage and verification.
    function _split(address account, uint256 nonce) private view returns (uint256 wordId, uint256 word, uint256 mask) {
        wordId = nonce >> 8;
        mask = 1 << (nonce & 0xff);
        word = _usedNonces[account][wordId];
    }
}
