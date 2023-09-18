// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IAccountFactory} from "src/cores/account/factory/interface/IAccountFactory.sol";
import {AccountFactoryStorage} from "src/cores/account/factory/AccountFactoryStorage.sol";
import {Ownable} from "src/access/ownable/Ownable.sol";

/// @title Station Network Account Factory Contract
/// @author 👦🏻👦🏻.eth

/// @dev This AccountFactory contract uses the `CREATE2` opcode to deterministically
/// deploy a new ERC1271 and ERC4337 compliant Account to a counterfactual address.
/// Deployments can be precomputed using the deployer address, random salt, and
/// a keccak hash of the contract's creation code
abstract contract AccountFactory is Ownable, IAccountFactory {
    /*====================
        ACCOUNTFACTORY
    ====================*/

    /// @dev Function to set the implementation address whose logic will be used by deployed account proxies
    function setAccountImpl(address newAccountImpl) external onlyOwner {
        _updateAccountImpl(newAccountImpl);
    }

    /// @dev Function to get the implementation address whose logic is used by deployed account  proxies
    function getAccountImpl() public view returns (address) {
        return AccountFactoryStorage.layout().accountImpl;
    }

    /// @dev Function to simulate a `CREATE2` deployment using a given salt and desired AccountType
    function simulateCreate2(bytes32 salt, bytes32 creationCodeHash) public view returns (address) {
        return _simulateCreate2(salt, creationCodeHash);
    }

    /*===============
        INTERNALS
    ===============*/

    function _updateAccountImpl(address _newAccountImpl) internal {
        if (_newAccountImpl == address(0x0)) revert InvalidImplementation();

        AccountFactoryStorage.Layout storage layout = AccountFactoryStorage.layout();
        layout.accountImpl = _newAccountImpl;

        emit AccountImplUpdated(_newAccountImpl);
    }

    function _simulateCreate2(bytes32 _salt, bytes32 _creationCodeHash)
        internal
        view
        returns (address simulatedDeploymentAddress)
    {
        assembly {
            let ptr := mload(0x40) // instantiate free mem pointer

            mstore(add(ptr, 0x0b), 0xff) // insert single byte create2 constant at 11th offset (starting from 0)
            mstore(ptr, address()) // insert 20-byte deployer address at 12th offset
            mstore(add(ptr, 0x20), _salt) // insert 32-byte salt at 32nd offset
            mstore(add(ptr, 0x40), _creationCodeHash) // insert 32-byte creationCodeHash at 64th offset

            // hash all inserted data, which is 85 bytes long, starting from 0xff constant at 11th offset
            simulatedDeploymentAddress := keccak256(add(ptr, 0x0b), 85)
        }
    }
}
