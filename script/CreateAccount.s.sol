// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ScriptUtils} from "script/utils/ScriptUtils.sol";
import {AccountCollectionProxy} from "src/cores/AccountCollection/AccountCollectionProxy.sol";
import {IAccountInitializer} from "src/cores/AccountCollection/interface/IAccountInitializer.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

/// @dev Script to deploy new implementations of BotAccount.sol and CallPermitValidator.sol only.
/// To deploy a factory enabling permissionless creation of proxy accounts, see BotAccountFactory.s.sol
contract CreateAccountScript is ScriptUtils {
    function run() public {
        /*=================
            ENVIRONMENT 
        =================*/

        /// @dev The following contracts will be deployed and initialized by this script
        address erc6551Registry = 0x02101dfB77FDE026414827Fdc604ddAF224F0921;
        // address accountCollectionProxy = 0xcB5F5408f5b82e51a0A5A5E58CF65575349a19d8;
        address accountCollectionProxy = 0x1142e4d0a3dB7b472ecF105880DA0359e0426766; // self, no assembly
        // address accountProxy = 0x2641e5d41F02B597e4E5C027252FF9C6D38AF023; // normal AccountProxy
        // address accountImpl = 0x1a0E97Dae78590b7E967E725a5c848eD034f5510; // FP v1/v2
        // address accountImpl = 0x6EB5334721197f0E48fef598C23b567bf87C2bc2; // MemberAccount
        // address accountImpl = 0x95e66fCE25C1c34635795C1059db9d29e9600d47; // MemberAccount with execute fix
        address accountImpl = 0xF672847Ec1666AFcBFAcA038f314C20A2B33D53D; // MemberAccount polygon
        uint256 tokenChainId = 137;
        address tokenContractAddress = 0x92E4277401A0eA0F4C78e059496c386013B1E662;
        uint256 tokenId = 3;
        uint256 counter = 0;

        /*===============
            BROADCAST 
        ===============*/

        vm.startBroadcast();
        // string memory saltString = ScriptUtils.readSalt("salt");
        // bytes32 salt = bytes32(bytes(saltString));

        bytes memory accountInitData = abi.encodeWithSignature("initialize(address)", turnkey); // initializer for MemberAccount
        bytes memory initData =
            abi.encodeWithSelector(IAccountInitializer.initializeAccount.selector, accountImpl, accountInitData);
        IERC6551Registry(erc6551Registry).createAccount(
            accountCollectionProxy, tokenChainId, tokenContractAddress, tokenId, counter, initData
        );

        // ScriptUtils.writeUsedSalt(
        //     saltString, string.concat("AccountCollectionProxy @", Strings.toHexString(address(accountCollectionProxy)))
        // );
        vm.stopBroadcast();
    }
}

interface IERC6551Registry {
    /**
     * @dev The registry SHALL emit the AccountCreated event upon successful account creation
     */
    event AccountCreated(
        address account,
        address indexed implementation,
        uint256 chainId,
        address indexed tokenContract,
        uint256 indexed tokenId,
        uint256 salt
    );

    /**
     * @dev Creates a token bound account for a non-fungible token
     *
     * If account has already been created, returns the account address without calling create2
     *
     * If initData is not empty and account has not yet been created, calls account with
     * provided initData after creation
     *
     * Emits AccountCreated event
     *
     * @return the address of the account
     */
    function createAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 seed,
        bytes calldata initData
    ) external returns (address);

    /**
     * @dev Returns the computed token bound account address for a non-fungible token
     *
     * @return The computed address of the token bound account
     */
    function account(address implementation, uint256 chainId, address tokenContract, uint256 tokenId, uint256 salt)
        external
        view
        returns (address);
}
