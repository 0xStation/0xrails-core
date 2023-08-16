// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Address} from "openzeppelin-contracts/utils/Address.sol";

import {Mage} from "../../Mage.sol";
import {Ownable, OwnableInternal} from "../../access/ownable/Ownable.sol";
import {Access} from "../../access/Access.sol";
import {ERC721AUpgradeable} from "./ERC721AUpgradeable.sol";
import {
    ITokenURIExtension, IContractURIExtension
} from "../../extension/examples/metadataRouter/IMetadataExtensions.sol";
import {Operations} from "../../lib/Operations.sol";
import {PermissionsStorage} from "../../access/permissions/PermissionsStorage.sol";
import {IERC721Mage} from "./interface/IERC721Mage.sol";
import {Initializable} from "../../lib/initializable/Initializable.sol";

/// @notice apply Mage pattern to ERC721 NFTs
/// @dev ERC721A chosen for only practical solution for large token supply allocations
contract ERC721Mage is Mage, Ownable, Initializable, ERC721AUpgradeable, IERC721Mage {
    // override starting tokenId exposed by 721A
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // owner stored explicitly
    function owner() public view override(Access, OwnableInternal) returns (address) {
        return OwnableInternal.owner();
    }

    /// @dev cannot call initialize within a proxy constructor, only post-deployment in a factory
    function initialize(address owner_, string calldata name_, string calldata symbol_, bytes calldata initData)
        external
        initializer
    {
        ERC721AUpgradeable._initialize(name_, symbol_);
        if (initData.length > 0) {
            /// @dev if called within a constructor, self-delegatecall will not work because this address does not yet have
            /// bytecode implementing the init functions -> revert here with nicer error message
            if (address(this).code.length == 0) {
                revert CannotInitializeWhileConstructing();
            }
            // make msg.sender the owner to ensure they have all permissions for further initialization
            _transferOwnership(msg.sender);
            Address.functionDelegateCall(address(this), initData);
            // if sender and owner arg are different, transfer ownership to desired address
            if (msg.sender != owner_) {
                _transferOwnership(owner_);
            }
        } else {
            _transferOwnership(owner_);
        }
    }

    /*==============
        METADATA
    ==============*/

    function supportsInterface(bytes4 interfaceId) public view override(Mage, ERC721AUpgradeable) returns (bool) {
        return Mage.supportsInterface(interfaceId) || ERC721AUpgradeable.supportsInterface(interfaceId);
    }

    // must override ERC721A implementation
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // to avoid clashing selectors, use standardized `ext_` prefix
        return ITokenURIExtension(address(this)).ext_tokenURI(tokenId);
    }

    // include contractURI as modern standard for NFTs
    function contractURI() public view override returns (string memory) {
        // to avoid clashing selectors, use standardized `ext_` prefix
        return IContractURIExtension(address(this)).ext_contractURI();
    }

    /*=============
        SETTERS
    =============*/

    function mintTo(address recipient, uint256 quantity) external onlyPermission(Operations.MINT) {
        _safeMint(recipient, quantity);
    }

    function burn(uint256 tokenId) external {
        if (msg.sender != ownerOf(tokenId)) {
            _checkPermission(Operations.BURN, msg.sender);
        }
        _burn(tokenId);
    }

    /*===========
        GUARD
    ===========*/

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        view
        override
    {
        (bytes8 operation, bytes memory data) = _getGuardParams(from, to, startTokenId, quantity);
        checkGuardBefore(operation, data);
    }

    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        view
        override
    {
        (bytes8 operation, bytes memory data) = _getGuardParams(from, to, startTokenId, quantity);
        checkGuardAfter(operation, data);
    }

    function _getGuardParams(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        view
        returns (bytes8 operation, bytes memory data)
    {
        if (from == address(0)) {
            operation = Operations.MINT;
        } else if (to == address(0)) {
            operation = Operations.BURN;
        } else {
            operation = Operations.TRANSFER;
        }
        data = abi.encode(msg.sender, from, to, startTokenId, quantity);

        return (operation, data);
    }
}
