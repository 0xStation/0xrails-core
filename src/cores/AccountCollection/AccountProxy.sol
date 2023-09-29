// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/proxy/ERC1967/ERC1967Upgrade.sol";
import "openzeppelin-contracts/proxy/Proxy.sol";

contract AccountProxy is Proxy, ERC1967Upgrade {
    function initialize(address implementation) external {
        ERC1967Upgrade._upgradeTo(implementation);
    }

    function _implementation() internal view override returns (address) {
        return ERC1967Upgrade._getImplementation();
    }
}
