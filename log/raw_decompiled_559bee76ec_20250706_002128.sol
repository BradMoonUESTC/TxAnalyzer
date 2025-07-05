// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title            Decompiled Contract
/// @author           Jonathan Becker <jonathan@jbecker.dev>
/// @custom:version   heimdall-rs v0.9.0
///
/// @notice           This contract was decompiled using the heimdall-rs decompiler.
///                     It was generated directly by tracing the EVM opcodes from this contract.
///                     As a result, it may not compile or even be valid solidity code.
///                     Despite this, it should be obvious what each function does. Overall
///                     logic should have been preserved throughout decompiling.
///
/// @custom:github    You can find the open-source decompiler here:
///                       https://heimdall.rs

contract DecompiledContract {
    uint256 public nodeRate;
    uint256 public node_amount;
    mapping(bytes32 => bytes32) storage_map_c;
    address public unresolved_f006ead6;
    mapping(bytes32 => bytes32) storage_map_ac;
    uint256 ownerh;
    address public unresolved_f127864c;
    address ownerd;
    bytes32 store_v;
    uint256 public unresolved_4b8cee65;
    address public ownerB;
    uint256 public unresolved_971cca57;
    uint256 public sellRate;
    uint256 public unresolved_b5305bdc;
    uint256 public unresolved_f8560a28;
    uint256 public returnRate;
    mapping(bytes32 => bytes32) storage_map_d;
    uint256 public unresolved_2c97e90c;
    address public marktingAddress;
    address public unresolved_fb9e5eca;
    mapping(bytes32 => bytes32) storage_map_ab;
    uint256 public unresolved_13caa51e;
    address public unresolved_59e2a23a;
    address public unresolved_be3c5152;
    mapping(bytes32 => bytes32) storage_map_g;
    address public unresolved_1cbe0fe2;
    address public owner;
    uint256 public unresolved_f6afce5f;
    uint256 store_e;
    address public usdtAddress;
    uint256 public buyRate;
    uint256 public unresolved_c09d1e58;
    mapping(bytes32 => bytes32) storage_map_n;
    mapping(bytes32 => bytes32) storage_map_o;
    uint256 public startTime;
    address public defaultAddress;
    uint256 public minBNBAmount;
    bytes32 ownerj;
    
    event OwnershipTransferred(address, address);
    
    /// @custom:selector    0xcbf6d902
    /// @custom:signature   Unresolved_cbf6d902(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_cbf6d902(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        usdtAddress = (uint96(usdtAddress)) | (address(arg0));
        return ;
    }
    
    /// @custom:selector    0x489082df
    /// @custom:signature   takeToken(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function takeToken(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(address(arg0), "no right to buy");
        address var_a = address(arg0);
        var_b = 0xb5;
        require(bytes1(storage_map_c[var_a]), "no right to buy");
        var_a = address(arg0);
        var_b = 0xb7;
        storage_map_c[var_a] = 0;
        storage_map_d[var_a] = store_e;
        require(!(msg.sender == (address(unresolved_59e2a23a))), "no right to buy");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x0f;
        var_f = 0x6e6f20726967687420746f206275790000000000000000000000000000000000;
        var_a = address(arg0);
        var_b = 0xb4;
        require(storage_map_c[var_a], "can not do this action");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x16;
        var_f = 0x63616e206e6f7420646f207468697320616374696f6e00000000000000000000;
        require(address(arg0));
        var_a = address(arg0);
        var_b = 0xb7;
        require(!storage_map_c[var_a]);
        storage_map_c[var_a] = 0;
        require(storage_map_g[var_a] > (storage_map_g[var_a] + storage_map_c[var_a]));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        storage_map_g[var_a] = (storage_map_g[var_a]) + storage_map_c[var_a];
        address var_c = storage_map_c[var_a];
        return storage_map_c[var_a];
        var_c = storage_map_c[var_a];
        return storage_map_c[var_a];
        var_c = 0;
        return 0;
        var_b = 0xb9;
        var_b = 0xb7;
        require((store_e - (storage_map_d[var_a])) > store_e);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        require(!(storage_map_c[var_a] * (store_e - (storage_map_d[var_a])) / storage_map_c[var_a] == (store_e - (storage_map_d[var_a]))) | !storage_map_c[var_a]);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        var_a = address(arg0);
        var_b = 0xb7;
        require((storage_map_c[var_a] * (store_e - (storage_map_d[var_a])) / 0x0de0b6b3a7640000) > ((storage_map_c[var_a] * (store_e - (storage_map_d[var_a])) / 0x0de0b6b3a7640000) + storage_map_c[var_a]));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
    }
    
    /// @custom:selector    0x72cd9cd7
    /// @custom:signature   Unresolved_72cd9cd7(uint256 arg0) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_72cd9cd7(uint256 arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, "Ownable: caller is not the owner");
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        buyRate = arg0;
        return ;
    }
    
    /// @custom:selector    0x6dfd480b
    /// @custom:signature   Unresolved_6dfd480b(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_6dfd480b(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        require(!(address(arg0)), "can not be zero address");
        ownerB = (uint96(ownerB)) | (address(arg0));
        return ;
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x17;
        var_d = 0x63616e206e6f74206265207a65726f2061646472657373000000000000000000;
    }
    
    /// @custom:selector    0x87ceff09
    /// @custom:signature   getBlockTime() public view returns (uint256)
    function getBlockTime() public view returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        uint256 var_a = block.timestamp;
        return block.timestamp;
    }
    
    /// @custom:selector    0x306c1f0c
    /// @custom:signature   updateAllAverage(uint256 arg0) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function updateAllAverage(uint256 arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, "no right to buy");
        require(!(msg.sender == (address(unresolved_59e2a23a))), "no right to buy");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x0f;
        var_d = 0x6e6f20726967687420746f206275790000000000000000000000000000000000;
        require(unresolved_c09d1e58);
        require(arg0);
        require(arg0 | (((arg0 * 0x0de0b6b3a7640000) / arg0) == 0x0de0b6b3a7640000));
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_f = 0x11;
        require(!unresolved_c09d1e58);
        require(store_e > (store_e + ((arg0 * 0x0de0b6b3a7640000) / unresolved_c09d1e58)));
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_f = 0x11;
        store_e = store_e + ((arg0 * 0x0de0b6b3a7640000) / unresolved_c09d1e58);
        return ;
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_f = 0x12;
        return ;
    }
    
    /// @custom:selector    0x8e047f0f
    /// @custom:signature   Unresolved_8e047f0f(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_8e047f0f(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(!(msg.sender == (address(unresolved_be3c5152))), "no right to buy");
        require(!(msg.sender == (address(owner))), "no right to buy");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x0f;
        var_d = 0x6e6f20726967687420746f206275790000000000000000000000000000000000;
        require(address(arg0));
        address var_e = address(arg0);
        var_f = 0xb5;
        require(bytes1(storage_map_n[var_e]));
        var_e = address(arg0);
        var_f = 0xb7;
        storage_map_n[var_e] = 0;
        storage_map_o[var_e] = store_e;
        var_e = address(arg0);
        var_f = 0xb5;
        storage_map_n[var_e] = (uint248(storage_map_n[var_e])) | 0x01;
        var_f = 0xb9;
        require((unresolved_c09d1e58 - storage_map_n[var_e]) > unresolved_c09d1e58);
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        unresolved_c09d1e58 = unresolved_c09d1e58 - storage_map_n[var_e];
        return ;
        var_f = 0xb9;
        var_f = 0xb7;
        require((store_e - (storage_map_o[var_e])) > store_e);
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        require(!(storage_map_n[var_e] * (store_e - (storage_map_o[var_e])) / storage_map_n[var_e] == (store_e - (storage_map_o[var_e]))) | !storage_map_n[var_e]);
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        var_e = address(arg0);
        var_f = 0xb7;
        require((storage_map_n[var_e] * (store_e - (storage_map_o[var_e])) / 0x0de0b6b3a7640000) > ((storage_map_n[var_e] * (store_e - (storage_map_o[var_e])) / 0x0de0b6b3a7640000) + storage_map_n[var_e]));
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
    }
    
    /// @custom:selector    0x90c6bd11
    /// @custom:signature   Unresolved_90c6bd11(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_90c6bd11(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        unresolved_f127864c = (uint96(unresolved_f127864c)) | (address(arg0));
        return ;
    }
    
    /// @custom:selector    0x8aa5b2c3
    /// @custom:signature   changeStartTime(uint256 arg0) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function changeStartTime(uint256 arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, "Ownable: caller is not the owner");
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        startTime = arg0;
        return ;
    }
    
    /// @custom:selector    0x191437a1
    /// @custom:signature   getBuyerAtIndex(uint256 arg0) public view returns (address)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function getBuyerAtIndex(uint256 arg0) public view returns (address) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        uint256 var_a = arg0;
        var_b = 0xba;
        uint256 var_c = address(storage_map_c[var_a]);
        return address(storage_map_c[var_a]);
    }
    
    /// @custom:selector    0x8881e443
    /// @custom:signature   Unresolved_8881e443(uint256 arg0) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_8881e443(uint256 arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, "Ownable: caller is not the owner");
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        unresolved_2c97e90c = arg0;
        return ;
    }
    
    /// @custom:selector    0xe17b2e29
    /// @custom:signature   Unresolved_e17b2e29(address arg0) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_e17b2e29(address arg0) public view returns (bytes memory) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        var_b = 0xb7;
        address var_c = storage_map_c[var_a];
        address var_d = storage_map_d[var_a];
        address var_e = storage_map_g[var_a];
        return abi.encodePacked(storage_map_c[var_a], storage_map_d[var_a], storage_map_g[var_a]);
    }
    
    /// @custom:selector    0x87e7e7a4
    /// @custom:signature   Unresolved_87e7e7a4(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_87e7e7a4(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        defaultAddress = (uint96(defaultAddress)) | (address(arg0));
        return ;
    }
    
    /// @custom:selector    0x90171e59
    /// @custom:signature   Unresolved_90171e59(uint256 arg0) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_90171e59(uint256 arg0) public view {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(((var_a + 0xc0) > 0xffffffffffffffff) | ((var_a + 0xc0) < var_a));
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_c = 0x41;
        uint256 var_a = var_a + 0xc0;
        uint256 var_d = 0;
        uint256 var_e = 0;
        uint256 var_f = 0;
        uint256 var_g = 0;
        uint256 var_h = 0;
        uint256 var_i = 0;
        require(!(((arg0 * unresolved_13caa51e) / arg0) == unresolved_13caa51e) | !arg0);
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_c = 0x11;
    }
    
    /// @custom:selector    0xe4997dc5
    /// @custom:signature   removeBlackList(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function removeBlackList(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(!(msg.sender == (address(unresolved_be3c5152))), "no right to buy");
        require(!(msg.sender == (address(owner))), "no right to buy");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x0f;
        var_d = 0x6e6f20726967687420746f206275790000000000000000000000000000000000;
        address var_e = address(arg0);
        var_f = 0xb4;
        require(!storage_map_n[var_e]);
        require((0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff + storage_map_n[var_e]) > storage_map_n[var_e]);
        require((store_v + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) > store_v);
        require((store_v + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff + storage_map_n[var_e]));
        require(!(store_v + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < store_v);
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x32;
        require(!store_v);
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x31;
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        var_e = address(arg0);
        var_f = 0xb5;
        storage_map_n[var_e] = uint248(storage_map_n[var_e]);
        var_f = 0xb7;
        storage_map_o[var_e] = store_e;
        var_f = 0xb9;
        require(unresolved_c09d1e58 > (unresolved_c09d1e58 + storage_map_n[var_e]));
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        unresolved_c09d1e58 = unresolved_c09d1e58 + storage_map_n[var_e];
        return ;
    }
    
    /// @custom:selector    0x52d766be
    /// @custom:signature   Unresolved_52d766be(uint256 arg0, uint256 arg1, uint256 arg2, uint256 arg3, uint256 arg4) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg3 ["uint256", "bytes32", "int256"]
    /// @param              arg4 ["uint256", "bytes32", "int256"]
    function Unresolved_52d766be(uint256 arg0, uint256 arg1, uint256 arg2, uint256 arg3, uint256 arg4) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0xa0, "Ownable: caller is not the owner");
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        unresolved_13caa51e = arg0;
        nodeRate = arg1;
        unresolved_4b8cee65 = arg2;
        unresolved_f6afce5f = arg3;
        unresolved_f8560a28 = arg4;
        return ;
    }
    
    /// @custom:selector    0xca8b444e
    /// @custom:signature   Unresolved_ca8b444e(address arg0) public payable returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_ca8b444e(address arg0) public payable returns (bytes memory) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        var_a = 0x6d8d64bf00000000000000000000000000000000000000000000000000000000;
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(ownera).Unresolved_6d8d64bf(var_b); // staticcall
        if (var_c > 0xffffffffffffffff) {
            var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            var_d = 0x41;
            require(var_c > 0xffffffffffffffff);
            var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            var_d = 0x41;
            uint248 var_e = var_e + (uint248((0x20 + (var_c << 0x05)) + 0x1f));
            var_a = var_c;
            require(((var_e + (uint248((0x20 + (var_c << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_e + (uint248((0x20 + (var_c << 0x05)) + 0x1f))) < var_e));
            var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            var_d = 0x41;
            var_f = msg.data[4:4];
            require(var_c > 0xffffffffffffffff);
            require(!0 < var_c);
            require(!0 < var_c);
            address var_c = address(var_g);
            var_g = 0xb6;
            require(address(var_g));
            var_c = address(var_g);
            var_g = 0xb4;
            require(bytes1(storage_map_ab[var_c]));
            address var_h = address(defaultAddress);
            require(storage_map_ab[var_c]);
            var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            var_d = 0x11;
            var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            var_d = 0x32;
            var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            var_d = 0x32;
            require(0 == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        }
        var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_d = 0x32;
        var_h = 0x20;
        uint248 var_i = var_e.length;
        return abi.encodePacked(0x20, var_e.length);
    }
    
    /// @custom:selector    0xfcfad9ce
    /// @custom:signature   Unresolved_fcfad9ce(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_fcfad9ce(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        address var_e = address(arg0);
        var_f = 0xb5;
        storage_map_n[var_e] = uint248(storage_map_n[var_e]);
        var_f = 0xb7;
        storage_map_ac[var_e] = store_e;
        var_f = 0xb9;
        require(unresolved_c09d1e58 > (unresolved_c09d1e58 + storage_map_n[var_e]));
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        unresolved_c09d1e58 = unresolved_c09d1e58 + storage_map_n[var_e];
        return ;
    }
    
    /// @custom:selector    0xdcb49479
    /// @custom:signature   Unresolved_dcb49479(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_dcb49479(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        ownerd = (uint96(ownerd)) | (address(arg0));
        return ;
    }
    
    /// @custom:selector    0x1904d164
    /// @custom:signature   Unresolved_1904d164(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_1904d164(address arg0) public view returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        var_b = 0xb6;
        address var_c = !(!bytes1(storage_map_c[var_a]));
        return !(!bytes1(storage_map_c[var_a]));
    }
    
    /// @custom:selector    0xf83212af
    /// @custom:signature   Unresolved_f83212af(uint256 arg0) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_f83212af(uint256 arg0) public view {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(!(((arg0 * sellRate) / arg0) == sellRate) | !arg0);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_b = 0x11;
    }
    
    /// @custom:selector    0xde41768c
    /// @custom:signature   Unresolved_de41768c(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_de41768c(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        unresolved_be3c5152 = (uint96(unresolved_be3c5152)) | (address(arg0));
        return ;
    }
    
    /// @custom:selector    0xdb66170a
    /// @custom:signature   Unresolved_db66170a(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_db66170a(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        unresolved_1cbe0fe2 = (uint96(unresolved_1cbe0fe2)) | (address(arg0));
        return ;
    }
    
    /// @custom:selector    0xbabb603b
    /// @custom:signature   Unresolved_babb603b(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_babb603b(address arg0) public payable {
        require(0x20 > (0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length));
        require(arg0 - (address(arg0)));
        require(address(arg0), "no right to buy");
        address var_a = address(arg0);
        var_b = 0xb5;
        require(bytes1(storage_map_c[var_a]), "no right to buy");
        var_a = address(arg0);
        var_b = 0xb7;
        storage_map_c[var_a] = 0;
        storage_map_d[var_a] = store_e;
        require(!(msg.sender == (address(unresolved_59e2a23a))), "no right to buy");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x0f;
        var_f = 0x6e6f20726967687420746f206275790000000000000000000000000000000000;
        require(address(arg0).code.length, "must user to buy");
        require(tx.origin - (address(arg0)), "must user to buy");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x10;
        var_f = 0x6d757374207573657220746f2062757900000000000000000000000000000000;
        var_a = address(arg0);
        var_b = 0xb9;
        require(storage_map_c[var_a] > (storage_map_c[var_a] + msg.value), "It needs to be greater than the minimum");
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        storage_map_c[var_a] = storage_map_c[var_a] + msg.value;
        require(msg.value < ownerg, "It needs to be greater than the minimum");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x27;
        var_f = 0x4974206e6565647320746f2062652067726561746572207468616e2074686520;
        var_h = 0x6d696e696d756d00000000000000000000000000000000000000000000000000;
        require(ownerh < (storage_map_c[var_a] + msg.value), "It needs to be less than the maximum");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x24;
        var_f = 0x4974206e6565647320746f206265206c657373207468616e20746865206d6178;
        var_h = 0x696d756d00000000000000000000000000000000000000000000000000000000;
        require(!(block.timestamp < startTime), "not start");
        require(!(!block.timestamp < startTime), "not start");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x09;
        var_f = 0x6e6f742073746172740000000000000000000000000000000000000000000000;
        require(startTime > (startTime + 0x012c));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        require(!block.timestamp > (startTime + 0x012c));
        var_c = 0x8c25635900000000000000000000000000000000000000000000000000000000;
        address var_d = address(arg0);
        (bool success, bytes memory ret0) = address(unresolved_f127864c).Unresolved_8c256359(var_d); // staticcall
        require(0, "wrong part or amount");
        require(!(msg.value == unresolved_2c97e90c), "wrong part or amount");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x14;
        var_f = 0x77726f6e672070617274206f7220616d6f756e74000000000000000000000000;
        var_a = address(arg0);
        var_b = 0xb6;
        require(!(!bytes1(storage_map_c[var_a])), "buy onece");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x09;
        var_f = 0x627579206f6e6563650000000000000000000000000000000000000000000000;
        require(!block.timestamp < (startTime + 0x012c));
        require(!block.timestamp < (startTime + 0x012c));
        var_a = address(arg0);
        var_b = 0xb6;
        storage_map_c[var_a] = 0x01 | (uint248(storage_map_c[var_a]));
        require(!(((msg.value * ownere) / msg.value) == ownere) | !msg.value);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        var_c = 0x8c25635900000000000000000000000000000000000000000000000000000000;
        var_d = address(arg0);
        (bool success, bytes memory ret0) = address(unresolved_1cbe0fe2).Unresolved_8c256359(var_d); // staticcall
        require(0, "wrong node or amount");
        require(!(msg.value == owneri), "wrong node or amount");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x14;
        var_f = 0x77726f6e67206e6f6465206f7220616d6f756e74000000000000000000000000;
        require(!0, "wrong node or amount");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x14;
        var_f = 0x77726f6e67206e6f6465206f7220616d6f756e74000000000000000000000000;
        require(0x20 > ret0.length);
        require(((var_i + 0x20) > 0xffffffffffffffff) | ((var_i + 0x20) < var_i));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x41;
        uint256 var_i = var_i + 0x20;
        require(((var_i + 0x20) - var_i) < 0x20);
        if (var_i.length - var_i.length) {
            require(var_i.length - var_i.length);
        }
        if (startTime > (startTime + 0x0384)) {
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            var_g = 0x11;
            require(startTime > (startTime + 0x0384), "wrong part or amount");
        }
        require(!0, "wrong part or amount");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x14;
        var_f = 0x77726f6e672070617274206f7220616d6f756e74000000000000000000000000;
        require(0x20 > ret0.length);
        require(((var_i + 0x20) > 0xffffffffffffffff) | ((var_i + 0x20) < var_i));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x41;
        var_i = var_i + 0x20;
        require(((var_i + 0x20) - var_i) < 0x20);
        if (var_i.length - var_i.length) {
            require(var_i.length - var_i.length);
        }
        require(!startTime, "not start");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x09;
        var_f = 0x6e6f742073746172740000000000000000000000000000000000000000000000;
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x0e;
        var_f = 0x63616e206e6f7420746f20627579000000000000000000000000000000000000;
        var_b = 0xb9;
        var_b = 0xb7;
        require((store_e - (storage_map_d[var_a])) > store_e);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        require(!(storage_map_c[var_a] * (store_e - (storage_map_d[var_a])) / storage_map_c[var_a] == (store_e - (storage_map_d[var_a]))) | !storage_map_c[var_a]);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
    }
    
    /// @custom:selector    0x1d1d630c
    /// @custom:signature   Unresolved_1d1d630c(uint256 arg0, uint256 arg1) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_1d1d630c(uint256 arg0, uint256 arg1) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40, "Ownable: caller is not the owner");
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        ownerg = arg0;
        ownerh = arg1;
        return ;
    }
    
    /// @custom:selector    0x715018a6
    /// @custom:signature   renounceOwnership() public payable returns (uint256)
    function renounceOwnership() public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        owner = uint96(owner);
        emit OwnershipTransferred(address(owner), 0);
        return ;
    }
    
    /// @custom:selector    0x8129fc1c
    /// @custom:signature   initialize() public payable
    function initialize() public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        require(!(bytes1(ownerj >> 0x08)), "Initializable: contract is not initializing");
        require(!(!bytes1(ownerj >> 0x08)), "Initializable: contract is not initializing");
        require(address(this).code.length, "Initializable: contract is not initializing");
        require(!(bytes1(ownerj) == 0x01), "Initializable: contract is not initializing");
        ownerj = 0x01 | (uint248(ownerj));
        require(!(bytes1(ownerj >> 0x08)), "Initializable: contract is not initializing");
        require(!(bytes1(ownerj >> 0x08)), "Initializable: contract is not initializing");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x2b;
        var_d = 0x496e697469616c697a61626c653a20636f6e7472616374206973206e6f742069;
        var_e = 0x6e697469616c697a696e67000000000000000000000000000000000000000000;
        ownerj = 0x0101 | (uint240(ownerj));
        require(!(bytes1(ownerj >> 0x08)), "Initializable: contract is not initializing");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x2b;
        var_d = 0x496e697469616c697a61626c653a20636f6e7472616374206973206e6f742069;
        var_e = 0x6e697469616c697a696e67000000000000000000000000000000000000000000;
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x2e;
        var_d = 0x496e697469616c697a61626c653a20636f6e747261637420697320616c726561;
        var_e = 0x647920696e697469616c697a6564000000000000000000000000000000000000;
        require(!(!bytes1(ownerj >> 0x08)), "Initializable: contract is already initialized");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x2e;
        var_d = 0x496e697469616c697a61626c653a20636f6e747261637420697320616c726561;
        var_e = 0x647920696e697469616c697a6564000000000000000000000000000000000000;
    }
    
    /// @custom:selector    0x931d93fc
    /// @custom:signature   buyerUserInfo(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function buyerUserInfo(address arg0) public view returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        var_b = 0xb9;
        address var_c = storage_map_c[var_a];
        return storage_map_c[var_a];
    }
    
    /// @custom:selector    0xcc6ddc9a
    /// @custom:signature   Unresolved_cc6ddc9a(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_cc6ddc9a(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        ownera = (uint96(ownera)) | (address(arg0));
        return ;
    }
    
    /// @custom:selector    0xe6363cb1
    /// @custom:signature   Unresolved_e6363cb1(address arg0, uint256 arg1) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_e6363cb1(address arg0, uint256 arg1) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (address(arg0)));
        require(!(msg.sender == (address(unresolved_be3c5152))), "no right to buy");
        require(!(msg.sender == (address(owner))), "no right to buy");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x0f;
        var_d = 0x6e6f20726967687420746f206275790000000000000000000000000000000000;
        address var_e = address(arg0);
        var_f = 0xb7;
        require(storage_map_n[var_e] > (storage_map_n[var_e] + arg1));
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        storage_map_n[var_e] = storage_map_n[var_e] + arg1;
        return ;
    }
    
    /// @custom:selector    0x0ecb93c0
    /// @custom:signature   addBlackList(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function addBlackList(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(!(msg.sender == (address(unresolved_be3c5152))), "no right to buy");
        require(!(msg.sender == (address(owner))), "no right to buy");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x0f;
        var_d = 0x6e6f20726967687420746f206275790000000000000000000000000000000000;
        address var_e = address(arg0);
        var_f = 0xb4;
        require(storage_map_n[var_e]);
        require(address(arg0));
        var_e = address(arg0);
        var_f = 0xb5;
        require(bytes1(storage_map_n[var_e]));
        var_e = address(arg0);
        var_f = 0xb7;
        storage_map_n[var_e] = 0;
        storage_map_o[var_e] = store_e;
        var_e = address(arg0);
        var_f = 0xb5;
        storage_map_n[var_e] = (uint248(storage_map_n[var_e])) | 0x01;
        var_f = 0xb9;
        require((unresolved_c09d1e58 - storage_map_n[var_e]) > unresolved_c09d1e58);
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        unresolved_c09d1e58 = unresolved_c09d1e58 - storage_map_n[var_e];
        return ;
        var_f = 0xb9;
        var_f = 0xb7;
        require((store_e - (storage_map_o[var_e])) > store_e);
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        require(!(storage_map_n[var_e] * (store_e - (storage_map_o[var_e])) / storage_map_n[var_e] == (store_e - (storage_map_o[var_e]))) | !storage_map_n[var_e]);
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        var_e = address(arg0);
        var_f = 0xb7;
        require((storage_map_n[var_e] * (store_e - (storage_map_o[var_e])) / 0x0de0b6b3a7640000) > ((storage_map_n[var_e] * (store_e - (storage_map_o[var_e])) / 0x0de0b6b3a7640000) + storage_map_n[var_e]));
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        require(!store_v < 0x010000000000000000);
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x41;
        store_v = store_v + 0x01;
        require(!store_v < store_v);
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x32;
    }
    
    /// @custom:selector    0x496b370e
    /// @custom:signature   indexUser(uint256 arg0) public view returns (address)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function indexUser(uint256 arg0) public view returns (address) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        uint256 var_a = arg0;
        var_b = 0xba;
        uint256 var_c = address(storage_map_c[var_a]);
        return address(storage_map_c[var_a]);
    }
    
    /// @custom:selector    0x35b03203
    /// @custom:signature   intro(address arg0) public view returns (address)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function intro(address arg0) public view returns (address) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        var_b = 0xb8;
        address var_c = address(storage_map_c[var_a]);
        return address(storage_map_c[var_a]);
    }
    
    /// @custom:selector    0xa654ac9e
    /// @custom:signature   Unresolved_a654ac9e(uint256 arg0) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_a654ac9e(uint256 arg0) public view {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(!(((arg0 * ownere) / arg0) == ownere) | !arg0);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_b = 0x11;
    }
    
    /// @custom:selector    0x9c4380e7
    /// @custom:signature   getToken(address arg0, address arg1, uint256 arg2) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function getToken(address arg0, address arg1, uint256 arg2) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        var_a = 0xa9059cbb00000000000000000000000000000000000000000000000000000000;
        address var_b = address(arg1);
        uint256 var_c = arg2;
        (bool success, bytes memory ret0) = address(arg0).{ value: 0 ether }Unresolved_a9059cbb(var_b); // call
        return ;
        require(0x20 > ret0.length);
        require(((var_e + 0x20) > 0xffffffffffffffff) | ((var_e + 0x20) < var_e));
        var_f = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x41;
        uint256 var_e = var_e + 0x20;
        require(((var_e + 0x20) - var_e) < 0x20);
        require(var_e.length - var_e.length);
        return ;
    }
    
    /// @custom:selector    0xf694fc1e
    /// @custom:signature   Unresolved_f694fc1e(uint256 arg0, address arg1) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_f694fc1e(uint256 arg0, address arg1) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg1 - (address(arg1)));
        require(address(arg1), "no right to buy");
        address var_a = address(arg1);
        var_b = 0xb5;
        require(bytes1(storage_map_c[var_a]), "no right to buy");
        var_a = address(arg1);
        var_b = 0xb7;
        storage_map_c[var_a] = 0;
        storage_map_d[var_a] = store_e;
        require(!(msg.sender == (address(unresolved_59e2a23a))), "no right to buy");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x0f;
        var_f = 0x6e6f20726967687420746f206275790000000000000000000000000000000000;
        var_a = address(arg1);
        var_b = 0xb4;
        require(storage_map_c[var_a], "in black");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x08;
        var_f = 0x696e20626c61636b000000000000000000000000000000000000000000000000;
        var_a = address(arg1);
        var_b = 0xb5;
        require(!bytes1(storage_map_c[var_a]));
        require(!(((arg0 * sellRate) / arg0) == sellRate) | !arg0);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        require(address(arg1));
        var_a = address(arg1);
        var_b = 0xb5;
        require(bytes1(storage_map_c[var_a]));
        var_a = address(arg1);
        var_b = 0xb7;
        storage_map_c[var_a] = 0;
        storage_map_d[var_a] = store_e;
        var_a = address(arg1);
        var_b = 0xb5;
        storage_map_c[var_a] = (uint248(storage_map_c[var_a])) | 0x01;
        var_b = 0xb9;
        require((unresolved_c09d1e58 - storage_map_c[var_a]) > unresolved_c09d1e58);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        var_b = 0xb9;
        var_b = 0xb7;
        require((store_e - (storage_map_d[var_a])) > store_e);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        require(!(storage_map_c[var_a] * (store_e - (storage_map_d[var_a])) / storage_map_c[var_a] == (store_e - (storage_map_d[var_a]))) | !storage_map_c[var_a]);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        var_a = address(arg1);
        var_b = 0xb7;
        require((storage_map_c[var_a] * (store_e - (storage_map_d[var_a])) / 0x0de0b6b3a7640000) > ((storage_map_c[var_a] * (store_e - (storage_map_d[var_a])) / 0x0de0b6b3a7640000) + storage_map_c[var_a]));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
    }
    
    /// @custom:selector    0xf2fde38b
    /// @custom:signature   transferOwnership(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function transferOwnership(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        require(!(address(arg0)), "Ownable: new owner is the zero address");
        owner = (address(arg0)) | (uint96(owner));
        emit OwnershipTransferred(address(owner), address(arg0));
        return ;
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x26;
        var_d = 0x4f776e61626c653a206e6577206f776e657220697320746865207a65726f2061;
        var_e = 0x6464726573730000000000000000000000000000000000000000000000000000;
    }
    
    /// @custom:selector    0x2a55feec
    /// @custom:signature   isBuyer(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function isBuyer(address arg0) public view returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        var_b = 0xb9;
        address var_c = !(ownerg > storage_map_c[var_a]);
        return !(ownerg > storage_map_c[var_a]);
    }
    
    /// @custom:selector    0x9cc6cf42
    /// @custom:signature   changeSellRate(uint256 arg0, uint256 arg1) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function changeSellRate(uint256 arg0, uint256 arg1) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40, "Ownable: caller is not the owner");
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        sellRate = arg0;
        ownerk = arg1;
        return ;
    }
    
    /// @custom:selector    0x9f5c18c4
    /// @custom:signature   Unresolved_9f5c18c4(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_9f5c18c4(address arg0) public view returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        var_b = 0xb5;
        address var_c = !(!bytes1(storage_map_c[var_a]));
        return !(!bytes1(storage_map_c[var_a]));
    }
    
    /// @custom:selector    0xa224fc4f
    /// @custom:signature   Unresolved_a224fc4f(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_a224fc4f(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(ownerB)), "no right");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x08;
        var_d = 0x6e6f207269676874000000000000000000000000000000000000000000000000;
        owner = (address(arg0)) | (uint96(owner));
        emit OwnershipTransferred(address(owner), address(arg0));
        return ;
    }
    
    /// @custom:selector    0x4184b3e0
    /// @custom:signature   Unresolved_4184b3e0(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_4184b3e0(address arg0) public view returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        var_b = 0xb9;
        address var_c = storage_map_c[var_a];
        return storage_map_c[var_a];
    }
    
    /// @custom:selector    0x9c1e8f4b
    /// @custom:signature   Unresolved_9c1e8f4b(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_9c1e8f4b(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        ownerf = (uint96(ownerf)) | (address(arg0));
        return ;
    }
    
    /// @custom:selector    0xf0b20ffe
    /// @custom:signature   Unresolved_f0b20ffe(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_f0b20ffe(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        unresolved_59e2a23a = (uint96(unresolved_59e2a23a)) | (address(arg0));
        return ;
    }
    
    /// @custom:selector    0x6be32086
    /// @custom:signature   Unresolved_6be32086(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_6be32086(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        ownerl = (uint96(ownerl)) | (address(arg0));
        return ;
    }
    
    /// @custom:selector    0x4a425148
    /// @custom:signature   Unresolved_4a425148(uint256 arg0) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_4a425148(uint256 arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, "Ownable: caller is not the owner");
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        owneri = arg0;
        return ;
    }
    
    /// @custom:selector    0x46de5f84
    /// @custom:signature   Unresolved_46de5f84(uint256 arg0, uint256 arg1) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_46de5f84(uint256 arg0, uint256 arg1) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40, "Ownable: caller is not the owner");
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        ownere = arg0;
        unresolved_b5305bdc = arg1;
        return ;
    }
    
    /// @custom:selector    0x52f46290
    /// @custom:signature   Unresolved_52f46290(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_52f46290(address arg0) public view returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        var_b = 0xb5;
        address var_c = !(!bytes1(storage_map_c[var_a]));
        return !(!bytes1(storage_map_c[var_a]));
    }
    
    /// @custom:selector    0x1454aef1
    /// @custom:signature   earnedToken(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function earnedToken(address arg0) public view returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        var_b = 0xb5;
        require(bytes1(storage_map_c[var_a]));
        uint256 var_c = 0;
        return 0;
        var_b = 0xb9;
        var_b = 0xb7;
        require((store_e - (storage_map_d[var_a])) > store_e);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_d = 0x11;
        require(!(storage_map_c[var_a] * (store_e - (storage_map_d[var_a])) / storage_map_c[var_a] == (store_e - (storage_map_d[var_a]))) | !storage_map_c[var_a]);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_d = 0x11;
        var_a = address(arg0);
        var_b = 0xb7;
        require((storage_map_c[var_a] * (store_e - (storage_map_d[var_a])) / 0x0de0b6b3a7640000) > ((storage_map_c[var_a] * (store_e - (storage_map_d[var_a])) / 0x0de0b6b3a7640000) + storage_map_c[var_a]));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_d = 0x11;
        var_c = (storage_map_c[var_a] * (store_e - (storage_map_d[var_a])) / 0x0de0b6b3a7640000) + storage_map_c[var_a];
        return (storage_map_c[var_a] * (store_e - (storage_map_d[var_a])) / 0x0de0b6b3a7640000) + storage_map_c[var_a];
    }
}