// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {UUPSUpgradeable} from "openzeppelin-contracts/proxy/utils/UUPSUpgradeable.sol";
import {Multicall} from "openzeppelin-contracts/utils/Multicall.sol";
import {Context} from "openzeppelin-contracts/utils/Context.sol";
import {Access} from "./access/Access.sol";
import {Guards} from "./guard/Guards.sol";
import {Extensions} from "./extension/Extensions.sol";
import {SupportsInterface} from "./lib/ERC165/SupportsInterface.sol";
import {Execute} from "./lib/Execute.sol";
import {Operations} from "./lib/Operations.sol";
import {ERC2771ContextInitializable} from "./lib/ERC2771/ERC2771ContextInitializable.sol";

/**
 * A Solidity framework for creating complex and evolving onchain structures.
 * All Rails-inherited contracts receive a batteries-included contract development kit.
 */
abstract contract Rails is Access, Guards, Extensions, SupportsInterface, Execute, Multicall, UUPSUpgradeable {
    /// @dev Function to return the contractURI for child contracts inheriting this one
    /// Unimplemented to abstract away this functionality and render it opt-in
    /// @return uri The returned contractURI string
    function contractURI() public view virtual returns (string memory uri) {}

    /// @inheritdoc SupportsInterface
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(Access, Guards, Extensions, SupportsInterface, Execute)
        returns (bool)
    {
        return Access.supportsInterface(interfaceId) || Guards.supportsInterface(interfaceId)
            || Extensions.supportsInterface(interfaceId) || SupportsInterface.supportsInterface(interfaceId)
            || Execute.supportsInterface(interfaceId);
    }

    /// @inheritdoc Execute
    function _beforeExecuteCall(address to, uint256 value, bytes calldata data)
        internal
        virtual
        override
        returns (address guard, bytes memory checkBeforeData)
    {
        return checkGuardBefore(Operations.CALL, abi.encode(to, value, data));
    }

    /// @inheritdoc Execute
    function _afterExecuteCall(address guard, bytes memory checkBeforeData, bytes memory executeData)
        internal
        virtual
        override
    {
        checkGuardAfter(guard, checkBeforeData, executeData);
    }

    /*=============
        CONTEXT
    =============*/

    function _msgSender() 
        internal 
        view 
        virtual 
        override(ERC2771ContextInitializable, Context) 
        returns (address) 
    {
        return ERC2771ContextInitializable._msgSender();
    }

    function _msgData() 
        internal 
        view 
        virtual 
        override(ERC2771ContextInitializable, Context) 
        returns (bytes calldata) 
    {
        return ERC2771ContextInitializable._msgData();
    }
}
