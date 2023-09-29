// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {Account} from "src/cores/account/Account.sol";
import {BaseAccount} from "src/cores/account/BaseAccount.sol";
import {IEntryPoint} from "src/lib/ERC4337/interface/IEntryPoint.sol";
import {UserOperation} from "src/lib/ERC4337/utils/UserOperation.sol";
import {ValidatorsStorage} from "src/validator/ValidatorsStorage.sol";
import {Initializable} from "src/lib/initializable/Initializable.sol";
import {Ownable} from "src/access/ownable/Ownable.sol";
import {OwnableInternal} from "src/access/ownable/OwnableInternal.sol";
import {Access} from "src/access/Access.sol";
import {Operations} from "src/lib/Operations.sol";
import {ERC6551AccountLib} from "../../lib/ERC6551/ERC6551AccountLib.sol";
import {IERC721} from "../ERC721/interface/IERC721.sol";

contract MemberAccount is Account, Initializable {
    /*==================
        BOT ACCOUNT
    ==================*/

    /// @param _entryPointAddress The contract address for this chain's ERC-4337 EntryPoint contract
    constructor(address _entryPointAddress) BaseAccount(_entryPointAddress) Initializable() {}

    // quickie implementation for letting a cloud wallet control the Account
    function initialize(address controller) external initializer {
        _addPermission(Operations.CALL, controller);
    }

    /*===============
        OVERRIDES
    ===============*/

    /// @dev When evaluating signatures that don't contain the `VALIDATOR_FLAG`, authenticate only the owner
    function _defaultValidateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 /*missingAccountFunds*/ )
        internal
        view
        virtual
        override
        returns (bool)
    {
        // recover signer address and any error
        (address signer, ECDSA.RecoverError err) = ECDSA.tryRecover(userOpHash, userOp.signature);
        // return if signature is malformed
        if (err != ECDSA.RecoverError.NoError) return false;
        // return if signer is not owner
        if (signer != owner()) return false;

        return true;
    }

    /// @dev When evaluating signatures that don't contain the `VALIDATOR_FLAG`, authenticate only the owner
    function _defaultIsValidSignature(bytes32 hash, bytes memory signature)
        internal
        view
        virtual
        override
        returns (bool)
    {
        // support non-modular signatures by recovering signer address and reverting malleable or invalid signatures
        (address signer, ECDSA.RecoverError err) = ECDSA.tryRecover(hash, signature);
        // return if signature is malformed
        if (err != ECDSA.RecoverError.NoError) return false;
        // return if signer is not owner
        if (signer != owner()) return false;

        return true;
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function _checkOwner() internal view {
        require(msg.sender == owner(), "NOT OWNER");
    }

    function owner() public view override returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = ERC6551AccountLib.token();
        return _tokenOwner(chainId, tokenContract, tokenId);
    }

    function _tokenOwner(uint256 chainId, address tokenContract, uint256 tokenId)
        internal
        view
        virtual
        returns (address)
    {
        if (chainId != block.chainid) return address(0);
        if (tokenContract.code.length == 0) return address(0);

        try IERC721(tokenContract).ownerOf(tokenId) returns (address _owner) {
            return _owner;
        } catch {
            return address(0);
        }
    }

    /// @dev Function to withdraw funds using the EntryPoint's `withdrawTo()` function
    /// @param recipient The address to receive from the EntryPoint balance
    /// @param amount The amount of funds to withdraw from the EntryPoint
    function withdrawFromEntryPoint(address payable recipient, uint256 amount) public virtual override onlyOwner {
        IEntryPoint(entryPoint).withdrawTo(recipient, amount);
    }

    // changes to core functionality must be restricted to owners to protect admins overthrowing
    function _checkCanUpdateExtensions() internal view override {
        _checkOwner();
    }

    function _authorizeUpgrade(address) internal view override {
        _checkOwner();
    }
}
