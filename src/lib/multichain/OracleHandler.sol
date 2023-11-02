// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC721} from "src/cores/ERC721/interface/IERC721.sol";
import {IPermissions} from "src/access/permissions/interface/IPermissions.sol";
import {Operations} from "src/lib/Operations.sol";
import {IOracleHandler} from "src/lib/multichain/IOracleHandler.sol";
import {TelepathyOracle} from "telepathy-contracts/oracle/TelepathyOracle.sol";
import {IOracleCallbackReceiver} from "telepathy-contracts/oracle/interfaces/IOracleCallbackReceiver.sol";

abstract contract OracleHandler is IOracleCallbackReceiver, IOracleHandler {

    address internal oracle;

    function handleOracleResponse(uint256 _nonce, bytes memory _responseData, bool _responseSuccess)
        external override 
    {
        if (msg.sender != oracle) {
            revert NotFromOracle(msg.sender);
        }
        if (!_responseSuccess) {
            revert OracleQueryFailed();
        }
        _handleOracleResponse(_nonce, _responseData, _responseSuccess);        
    }

    function setOracle(address _oracle) external override {
        IPermissions(address(this)).checkPermission(Operations.ADMIN, msg.sender);
        _setOracle(_oracle);
    }

    function _handleOracleResponse(uint256 _nonce, bytes memory _responseData, bool _responseSuccess) internal virtual;

    function _setOracle(address _oracle) internal {
        oracle = _oracle;
    }

    function _callOracle(address target, bytes memory data) internal returns (uint256 nonce) {
        nonce = TelepathyOracle(oracle).requestCrossChain(target, data, address(this));
    }
}