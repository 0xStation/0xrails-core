// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/SignatureChecker.sol";
import {ERC2771ContextInitializable} from "src/lib/ERC2771/ERC2771ContextInitializable.sol";
import {ERC2771Forwarder} from "src/lib/ERC2771/ERC2771Forwarder.sol";
import {ERC721Rails} from "src/cores/ERC721/ERC721Rails.sol";
import {Operations} from "src/lib/Operations.sol";
import {MockAccountDeployer} from "test/lib/MockAccount.sol";

contract ERC2771ForwarderTest is Test, MockAccountDeployer {
    ERC2771Forwarder public forwarder;
    ERC721Rails public ERC721RailsImpl;
    ERC721Rails public ERC721RailsProxy; // ERC1967 proxy wrapped in ERC721Rails for convenience

    uint256 public privateKey;
    uint256 public privateKey2;
    string public domainName;

    address public owner;
    string public name;
    string public symbol;
    bytes initData;

    address public from;
    address public recipient;
    uint48 deadline;
    bytes data1;
    bytes data2;
    bytes signature1;
    bytes signature2;
    ERC2771Forwarder.ForwardRequestData forwardRequestData1;
    ERC2771Forwarder.ForwardRequestData forwardRequestData2;

    bytes32 public constant FORWARD_REQUEST_TYPEHASH =
        keccak256(
            "ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,uint48 deadline,bytes data)"
        );
    bytes32 public DOMAIN_TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 public VERSION_HASH;
    bytes32 public NAME_HASH;
    bytes32 public domainSeparator;

    // to store errors
    bytes err;

    function setUp() public {
        privateKey2 = 0xdeadbeef;
        from = vm.addr(privateKey2);
        recipient = createAccount();
        domainName = "Forwarder";
        forwarder = new ERC2771Forwarder(domainName);
        
        (, string memory _retName, string memory _retVersion,,,,) = forwarder.eip712Domain();
        VERSION_HASH = keccak256(bytes(_retVersion));
        NAME_HASH = keccak256(bytes(_retName));
        domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPE_HASH, NAME_HASH, VERSION_HASH, block.chainid, address(forwarder))
        );

        // deploy and initialize erc721
        privateKey = 0xbeefEbabe;
        owner = vm.addr(privateKey);
        name = "Station";
        symbol = "STN";
        // include empty init data for setup
        initData = abi.encodeWithSelector(ERC721Rails.initialize.selector, owner, name, symbol, "", address(forwarder));

        ERC721RailsImpl = new ERC721Rails();
        ERC721RailsProxy = ERC721Rails(
            payable(
                address(
                    new ERC1967Proxy(
                    address(ERC721RailsImpl), 
                    initData
                    )
                )
            )
        );
        
        // grant mint permission to `from` address and controller so it can mint
        vm.startPrank(owner);
        ERC721RailsProxy.addPermission(Operations.MINT, from);
        vm.stopPrank();
    }

    function test_verify(uint8 amount) public {
        vm.assume(amount != 0);

        data1 = abi.encodeWithSelector(ERC721Rails.mintTo.selector, owner, uint256(amount));
        forwardRequestData1= ERC2771Forwarder.ForwardRequestData({
           from: owner,
           to: address(ERC721RailsProxy),
           value: 0,
           gas: 100000,
           deadline: type(uint48).max,
           data: data1,
           signature: ''
        });

        bytes32 valuesHash = keccak256(
            abi.encode(FORWARD_REQUEST_TYPEHASH, forwardRequestData1.from, forwardRequestData1.to, forwardRequestData1.value, forwardRequestData1.gas, forwarder.lastUsedNonce(forwardRequestData1.from, 0) + 1, forwardRequestData1.deadline, keccak256(forwardRequestData1.data))
        );

        bytes32 forwardRequestDataHash = ECDSA.toTypedDataHash(domainSeparator, valuesHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, forwardRequestDataHash);
        bytes memory sig = abi.encodePacked(r, s, v);
        forwardRequestData1.signature = sig;

        bool verified = forwarder.verify(forwardRequestData1);
        assertTrue(verified);
    }

    function test_execute(uint8 amount) public {
        vm.assume(amount != 0);
        vm.assume(amount < 228);

        data1 = abi.encodeWithSelector(ERC721Rails.mintTo.selector, recipient, uint256(amount));
        forwardRequestData1= ERC2771Forwarder.ForwardRequestData({
           from: owner,
           to: address(ERC721RailsProxy),
           value: 0,
           gas: 2000000,
           deadline: type(uint48).max,
           data: data1,
           signature: ''
        });

        bytes32 valuesHash = keccak256(
            abi.encode(FORWARD_REQUEST_TYPEHASH, forwardRequestData1.from, forwardRequestData1.to, forwardRequestData1.value, forwardRequestData1.gas, forwarder.lastUsedNonce(forwardRequestData1.from, 0) + 1, forwardRequestData1.deadline, keccak256(forwardRequestData1.data))
        );

        bytes32 forwardRequestDataHash = ECDSA.toTypedDataHash(domainSeparator, valuesHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, forwardRequestDataHash);
        bytes memory sig = abi.encodePacked(r, s, v);
        forwardRequestData1.signature = sig;


        forwarder.execute(forwardRequestData1);
        assertEq(ERC721RailsProxy.balanceOf(recipient), amount);
    }

    function test_executeBatch(uint8 amount1, uint8 amount2) public {
        vm.assume(amount1 != 0 && amount1 < 228);
        vm.assume(amount2 != 0 && amount2 < 228);

        data1 = abi.encodeWithSelector(ERC721Rails.mintTo.selector, recipient, uint256(amount1));
        forwardRequestData1 = ERC2771Forwarder.ForwardRequestData({
           from: owner,
           to: address(ERC721RailsProxy),
           value: 0,
           gas: 1000000,
           deadline: type(uint48).max,
           data: data1,
           signature: ''
        });

        bytes32 valuesHash1 = keccak256(
            abi.encode(FORWARD_REQUEST_TYPEHASH, forwardRequestData1.from, forwardRequestData1.to, forwardRequestData1.value, forwardRequestData1.gas, forwarder.lastUsedNonce(forwardRequestData1.from, 0) + 1, forwardRequestData1.deadline, keccak256(forwardRequestData1.data))
        );

        bytes32 forwardRequestDataHash1 = ECDSA.toTypedDataHash(domainSeparator, valuesHash1);

        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(privateKey, forwardRequestDataHash1);
        bytes memory sig1 = abi.encodePacked(r1, s1, v1);
        forwardRequestData1.signature = sig1;

        // create a second forwardRequestData1to provide in the batch
        data2 = abi.encodeWithSelector(ERC721Rails.mintTo.selector, from, uint256(amount2));
        forwardRequestData2 = ERC2771Forwarder.ForwardRequestData({
           from: from,
           to: address(ERC721RailsProxy),
           value: 0,
           gas: 1000000,
           deadline: type(uint48).max,
           data: data2,
           signature: ''
        });

        bytes32 valuesHash2 = keccak256(
            abi.encode(FORWARD_REQUEST_TYPEHASH, forwardRequestData2.from, forwardRequestData2.to, forwardRequestData2.value, forwardRequestData2.gas, forwarder.lastUsedNonce(forwardRequestData1.from, 0) + 1, forwardRequestData2.deadline, keccak256(forwardRequestData2.data))
        );

        bytes32 forwardRequestDataHash2 = ECDSA.toTypedDataHash(domainSeparator, valuesHash2);

        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(privateKey2, forwardRequestDataHash2);
        bytes memory sig2 = abi.encodePacked(r2, s2, v2);
        forwardRequestData2.signature = sig2;

        ERC2771Forwarder.ForwardRequestData[] memory requests = new ERC2771Forwarder.ForwardRequestData[](2);
        requests[0] = forwardRequestData1;
        requests[1] = forwardRequestData2;
        // using the zero address as refundreceiver causes batches to revert if one is invalid, 
        // which is a desirable outcome for testing
        forwarder.executeBatch(requests, payable(address(0x0)));
    }
}

