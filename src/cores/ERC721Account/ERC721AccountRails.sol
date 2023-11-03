// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";

import {AccountRails} from "src/cores/account/AccountRails.sol";
import {Account} from "src/cores/account/Account.sol";
import {IEntryPoint} from "src/lib/ERC4337/interface/IEntryPoint.sol";
import {UserOperation} from "src/lib/ERC4337/utils/UserOperation.sol";
import {ValidatorsStorage} from "src/validator/ValidatorsStorage.sol";
import {Initializable} from "src/lib/initializable/Initializable.sol";
import {Access} from "src/access/Access.sol";
import {Extensions} from "src/extension/Extensions.sol";
import {Operations} from "src/lib/Operations.sol";
import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";
import {IERC721, IERC721Internal} from "../ERC721/interface/IERC721.sol";
import {IERC721AccountRails} from "./interface/IERC721AccountRails.sol";
import {ERC6551Account, IERC6551Account} from "src/lib/ERC6551/ERC6551Account.sol";
import {ERC6551AccountStorage} from "src/lib/ERC6551/ERC6551AccountStorage.sol";
import {IERC6551AccountGroup} from "src/lib/ERC6551AccountGroup/interface/IERC6551AccountGroup.sol";
import {OracleHandler} from "src/lib/multichain/OracleHandler.sol";

/// @notice An ERC-4337 Account bound to an ERC-721 token via ERC-6551
contract ERC721AccountRails is AccountRails, ERC6551Account, Initializable, IERC721AccountRails, OracleHandler {

    struct MultichainCall {
        address sender;
        bytes data;
    }

    mapping(uint256 => MultichainCall) pendingCalls;

    /*====================
        INITIALIZATION
    ====================*/

    /// @param _entryPointAddress The contract address for this chain's ERC-4337 EntryPoint contract
    constructor(address _entryPointAddress) Account(_entryPointAddress) Initializable() {}

    /// @inheritdoc IERC721AccountRails
    /// @notice Important that it is assumed the caller of this function is trusted by the Account Group
    function initialize(address _oracle, bytes memory _initData) external initializer {
        // make msg.sender an ADMIN to ensure they have all permissions for further initialization
        _addPermission(Operations.ADMIN, msg.sender);
        _setOracle(_oracle);
        Address.functionDelegateCall(address(this), _initData);
        // remove sender ADMIN permissions
        _removePermission(Operations.ADMIN, msg.sender);
    }

    receive() external payable override(Extensions, IERC6551Account) {}

    /*==============
        METADATA
    ==============*/

    /// @inheritdoc AccountRails
    function supportsInterface(bytes4 interfaceId) public view override(AccountRails, ERC6551Account) returns (bool) {
        return AccountRails.supportsInterface(interfaceId) || ERC6551Account.supportsInterface(interfaceId);
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

    function _isValidSigner(address signer, bytes memory) internal view override returns (bool) {
        return hasPermission(Operations.CALL, signer);
    }

    /// @dev According to ERC6551, functions that modify state must alter the `uint256 state` variable
    function _beforeExecuteCall(address to, uint256 value, bytes calldata data) 
        internal
        virtual override
        returns (address, bytes memory)
    {
        ERC6551AccountStorage.layout().state++;
        super._beforeExecuteCall(to, value, data);
    }

    /*===================
        AUTHORIZATION
    ===================*/

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
        if (chainId != block.chainid) {
            return address(0);
        }
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
    function withdrawFromEntryPoint(address payable recipient, uint256 amount) public virtual override {
        _checkOwner();
        IEntryPoint(entryPoint).withdrawTo(recipient, amount);
    }

    // changes to core functionality must be restricted to owners to protect admins overthrowing
    function _checkCanUpdateExtensions() internal view override {
        _checkOwner();
    }

    function _authorizeUpgrade(address newImplementation) internal override {
        // if delegatecall is reached, auth checks have already passed
        if (msg.sender == address(this)) return;

        (uint256 chainId, address tokenContract, uint256 tokenId) = ERC6551AccountLib.token();
        if (chainId == block.chainid) {
            _checkOwner();
        } else {
            uint256 nonce = _callOracle(
                tokenContract,
                abi.encodeWithSelector(IERC721Internal.ownerOf.selector, tokenId)
            );
            // state stored is reverted if approved implementation check fails
            pendingCalls[nonce] = MultichainCall({sender: msg.sender, data: msg.data});
        }

        // fetch GroupAccount from contract bytecode in the context of delegatecall
        bytes32 bytecodeSalt = ERC6551AccountLib.salt(address(this));
        address accountGroup = address(bytes20(bytecodeSalt));
        
        // check for approved upgrade implementation match
        address[] memory upgradeOptions = IERC6551AccountGroup(accountGroup).getApprovedImplementations(address(this));
        unchecked {
            for (uint256 i; i < upgradeOptions.length; ++i) {
                if (upgradeOptions[i] == newImplementation) return;
            }
        }

        revert ImplementationNotApproved(newImplementation);
    }

    function _handleOracleResponse(uint256 _nonce, bytes memory _responseData, bool _responseSuccess) 
        internal virtual override 
    {
        MultichainCall memory pendingCall = pendingCalls[_nonce];
        address tokenOwner = abi.decode(_responseData, (address));

        if (tokenOwner == pendingCall.sender) {
            Address.functionDelegateCall(address(this), pendingCall.data);
        }

        // clear pending state in case of future oracle malfunction
        delete pendingCalls[_nonce];
    }
}
